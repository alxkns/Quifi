import Foundation
import CoreGraphics
import AppKit
import os.log

public protocol EventTapManagerDelegate: AnyObject {
    func eventTapTriggeredHUD(at location: CGPoint, isCopyModifierActive: Bool)
    func eventTapDidEndDrag()
    func eventTapModifierChanged(isCopyModifierActive: Bool)
}

public final class EventTapManager {
    public static let shared = EventTapManager()
    private let logger = Logger(subsystem: "org.quifi.app", category: "EventTapManager")

    public weak var delegate: EventTapManagerDelegate?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var globalDragMonitor: Any?
    private var globalFlagsMonitor: Any?
    private var globalUpMonitor: Any?

    private let shakeDetector = ShakeDetector()
    private var isDragging = false
    private var isHUDShown = false
    private var permissionTimer: Timer?

    public init() {
        shakeDetector.onShakeDetected = { [weak self] in
            guard let self = self, self.isDragging, !self.isHUDShown else { return }
            self.logger.info("[QuiFi] Shake gesture detected during drag!")
            let point = NSEvent.mouseLocation
            let isCopy = NSEvent.modifierFlags.contains(.option)
            self.isHUDShown = true
            DispatchQueue.main.async {
                self.delegate?.eventTapTriggeredHUD(at: point, isCopyModifierActive: isCopy)
            }
        }

        startPermissionMonitoring()
    }

    public func setHUDState(isShown: Bool) {
        self.isHUDShown = isShown
        if !isShown {
            shakeDetector.reset()
        }
    }

    /// Continuously monitors whether accessibility permissions were granted, auto-starting the monitors.
    private func startPermissionMonitoring() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let isGranted = AccessibilityHelper.isAccessibilityGranted
            if isGranted && self.eventTap == nil && self.globalDragMonitor == nil {
                self.logger.info("[QuiFi] Accessibility permission detected! Starting event monitors...")
                self.start()
            }
        }
    }

    public func start() {
        stop()

        guard AccessibilityHelper.isAccessibilityGranted else {
            logger.warning("[QuiFi] Cannot start: Accessibility permission not granted.")
            return
        }

        logger.info("[QuiFi] Starting event monitoring...")
        setupGlobalNSEventMonitors()
        setupCGEventTap()
    }

    public func stop() {
        if let dragMon = globalDragMonitor {
            NSEvent.removeMonitor(dragMon)
            globalDragMonitor = nil
        }
        if let flagsMon = globalFlagsMonitor {
            NSEvent.removeMonitor(flagsMon)
            globalFlagsMonitor = nil
        }
        if let upMon = globalUpMonitor {
            NSEvent.removeMonitor(upMon)
            globalUpMonitor = nil
        }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
                self.runLoopSource = nil
            }
            self.eventTap = nil
        }

        isDragging = false
        shakeDetector.reset()
        logger.info("[QuiFi] Event monitoring stopped.")
    }

    // MARK: - AppKit Global Event Monitors
    private func setupGlobalNSEventMonitors() {
        globalDragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            guard let self = self else { return }
            self.handleDragEvent(modifierFlags: event.modifierFlags)
        }

        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            guard let self = self else { return }
            self.handleFlagsChanged(modifierFlags: event.modifierFlags)
        }

        globalUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            guard let self = self else { return }
            self.handleMouseUp()
        }
    }

    // MARK: - CoreGraphics Event Tap (Low-level fallback)
    private func setupCGEventTap() {
        let eventMask: CGEventMask = (1 << CGEventType.leftMouseDragged.rawValue)
            | (1 << CGEventType.leftMouseUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        let observer = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()

                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let t = manager.eventTap {
                        CGEvent.tapEnable(tap: t, enable: true)
                    }
                    return Unmanaged.passUnretained(event)
                }

                manager.handleCGEvent(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: observer
        ) else {
            logger.error("[QuiFi] Failed to create CGEventTap")
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        logger.info("[QuiFi] CGEventTap active.")
    }

    // MARK: - Event Processing
    private func handleDragEvent(modifierFlags: NSEvent.ModifierFlags) {
        isDragging = true
        let mouseLocation = NSEvent.mouseLocation
        let prefs = PreferencesStore.shared.preferences

        if prefs.enableShakeTrigger && !isHUDShown {
            shakeDetector.sensitivity = prefs.shakeSensitivity
            shakeDetector.addPoint(x: mouseLocation.x)
        }

        if prefs.enableModifierTrigger && !isHUDShown {
            if isModifierActive(modifierFlags, target: prefs.triggerModifier) {
                triggerHUD(at: mouseLocation, flags: modifierFlags)
            }
        }
    }

    private func handleFlagsChanged(modifierFlags: NSEvent.ModifierFlags) {
        let prefs = PreferencesStore.shared.preferences
        let isCopy = isModifierActive(modifierFlags, target: prefs.copyModifier)

        DispatchQueue.main.async {
            self.delegate?.eventTapModifierChanged(isCopyModifierActive: isCopy)
        }

        if isDragging && prefs.enableModifierTrigger && !isHUDShown {
            if isModifierActive(modifierFlags, target: prefs.triggerModifier) {
                triggerHUD(at: NSEvent.mouseLocation, flags: modifierFlags)
            }
        }
    }

    private func handleMouseUp() {
        isDragging = false
        shakeDetector.reset()
        DispatchQueue.main.async {
            self.delegate?.eventTapDidEndDrag()
        }
    }

    private func handleCGEvent(type: CGEventType, event: CGEvent) {
        switch type {
        case .leftMouseDragged:
            let flags = event.flags
            let mouseLocation = NSEvent.mouseLocation
            let prefs = PreferencesStore.shared.preferences

            isDragging = true

            if prefs.enableShakeTrigger && !isHUDShown {
                shakeDetector.sensitivity = prefs.shakeSensitivity
                shakeDetector.addPoint(x: mouseLocation.x)
            }

            if prefs.enableModifierTrigger && !isHUDShown {
                if matchesCGModifier(flags: flags, modifier: prefs.triggerModifier) {
                    let isCopy = matchesCGModifier(flags: flags, modifier: prefs.copyModifier)
                    triggerHUD(at: mouseLocation, isCopy: isCopy)
                }
            }

        case .flagsChanged:
            let flags = event.flags
            let prefs = PreferencesStore.shared.preferences
            let isCopy = matchesCGModifier(flags: flags, modifier: prefs.copyModifier)

            DispatchQueue.main.async {
                self.delegate?.eventTapModifierChanged(isCopyModifierActive: isCopy)
            }

            if isDragging && prefs.enableModifierTrigger && !isHUDShown {
                if matchesCGModifier(flags: flags, modifier: prefs.triggerModifier) {
                    triggerHUD(at: NSEvent.mouseLocation, isCopy: isCopy)
                }
            }

        case .leftMouseUp:
            handleMouseUp()

        default:
            break
        }
    }

    private func triggerHUD(at point: CGPoint, flags: NSEvent.ModifierFlags) {
        let prefs = PreferencesStore.shared.preferences
        let isCopy = isModifierActive(flags, target: prefs.copyModifier)
        triggerHUD(at: point, isCopy: isCopy)
    }

    private func triggerHUD(at point: CGPoint, isCopy: Bool) {
        guard !isHUDShown else { return }
        isHUDShown = true
        logger.info("[QuiFi] Triggering HUD at Cocoa position: \(point.x), \(point.y)")

        DispatchQueue.main.async {
            self.delegate?.eventTapTriggeredHUD(at: point, isCopyModifierActive: isCopy)
        }
    }

    private func isModifierActive(_ flags: NSEvent.ModifierFlags, target: TriggerModifier) -> Bool {
        switch target {
        case .command:
            return flags.contains(.command)
        case .option:
            return flags.contains(.option)
        case .control:
            return flags.contains(.control)
        }
    }

    private func matchesCGModifier(flags: CGEventFlags, modifier: TriggerModifier) -> Bool {
        switch modifier {
        case .command:
            return flags.contains(.maskCommand)
        case .option:
            return flags.contains(.maskAlternate)
        case .control:
            return flags.contains(.maskControl)
        }
    }
}
