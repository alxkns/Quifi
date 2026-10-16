import Foundation
import CoreGraphics
import AppKit

public protocol EventTapManagerDelegate: AnyObject {
    func eventTapTriggeredHUD(at location: CGPoint, isCopyModifierActive: Bool)
    func eventTapDidEndDrag()
    func eventTapModifierChanged(isCopyModifierActive: Bool)
}

public final class EventTapManager {
    public static let shared = EventTapManager()

    public weak var delegate: EventTapManagerDelegate?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let shakeDetector = ShakeDetector()
    private var isDragging = false
    private var isHUDShown = false

    public init() {
        shakeDetector.onShakeDetected = { [weak self] in
            guard let self = self, self.isDragging, !self.isHUDShown else { return }
            let point = NSEvent.mouseLocation
            let isCopy = self.isCopyModifierPressed(flags: CGEventSource.flagsState(.combinedSessionState))
            self.isHUDShown = true
            DispatchQueue.main.async {
                self.delegate?.eventTapTriggeredHUD(at: point, isCopyModifierActive: isCopy)
            }
        }
    }

    public func setHUDState(isShown: Bool) {
        self.isHUDShown = isShown
        if !isShown {
            shakeDetector.reset()
        }
    }

    public func start() {
        stop()

        guard AccessibilityHelper.isAccessibilityGranted else {
            print("[QuiFi] Accessibility permissions not granted yet. Cannot start event tap.")
            return
        }

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
                manager.handleEvent(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: observer
        ) else {
            print("[QuiFi] Failed to create CGEventTap")
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("[QuiFi] Global Event Tap started successfully.")
    }

    public func stop() {
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
    }

    private func handleEvent(type: CGEventType, event: CGEvent) {
        let prefs = PreferencesStore.shared.preferences
        let flags = event.flags

        switch type {
        case .leftMouseDragged:
            isDragging = true
            let location = event.location

            if prefs.enableShakeTrigger && !isHUDShown {
                shakeDetector.sensitivity = prefs.shakeSensitivity
                shakeDetector.addPoint(x: location.x)
            }

            if prefs.enableModifierTrigger && !isHUDShown {
                let isTriggerModifierActive = matchesModifier(flags: flags, modifier: prefs.triggerModifier)
                if isTriggerModifierActive {
                    isHUDShown = true
                    let isCopy = isCopyModifierPressed(flags: flags)
                    DispatchQueue.main.async {
                        self.delegate?.eventTapTriggeredHUD(at: location, isCopyModifierActive: isCopy)
                    }
                }
            }

        case .flagsChanged:
            let isCopy = isCopyModifierPressed(flags: flags)
            DispatchQueue.main.async {
                self.delegate?.eventTapModifierChanged(isCopyModifierActive: isCopy)
            }

            if isDragging && prefs.enableModifierTrigger && !isHUDShown {
                let isTriggerModifierActive = matchesModifier(flags: flags, modifier: prefs.triggerModifier)
                if isTriggerModifierActive {
                    isHUDShown = true
                    let point = NSEvent.mouseLocation
                    DispatchQueue.main.async {
                        self.delegate?.eventTapTriggeredHUD(at: point, isCopyModifierActive: isCopy)
                    }
                }
            }

        case .leftMouseUp:
            isDragging = false
            shakeDetector.reset()
            DispatchQueue.main.async {
                self.delegate?.eventTapDidEndDrag()
            }

        default:
            break
        }
    }

    private func matchesModifier(flags: CGEventFlags, modifier: TriggerModifier) -> Bool {
        switch modifier {
        case .command:
            return flags.contains(.maskCommand)
        case .option:
            return flags.contains(.maskAlternate)
        case .control:
            return flags.contains(.maskControl)
        }
    }

    private func isCopyModifierPressed(flags: CGEventFlags) -> Bool {
        let prefs = PreferencesStore.shared.preferences
        return matchesModifier(flags: flags, modifier: prefs.copyModifier)
    }
}
