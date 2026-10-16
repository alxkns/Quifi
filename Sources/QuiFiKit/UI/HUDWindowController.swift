import AppKit
import SwiftUI
import Combine
import os.log

public final class HUDWindowController: NSObject {
    public static let shared = HUDWindowController()
    private let logger = Logger(subsystem: "org.quifi.app", category: "HUDWindowController")

    private var panel: NSPanel?
    public let viewModel = CascadingFolderViewModel()
    private var conflictWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private var initialMouseLocation: CGPoint = .zero
    private var anchoredOriginX: CGFloat = 0

    public override init() {
        super.init()
        setupPanel()
    }

    private func setupPanel() {
        let initialWidth: CGFloat = 220
        let initialHeight: CGFloat = 330

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.isFloatingPanel = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        let rootView = CascadingFolderView(viewModel: viewModel) { [weak self] urls, targetFolder in
            self?.handleDrop(urls: urls, targetFolder: targetFolder)
        }

        let hostingView = NSHostingView(rootView: rootView)
        panel.contentView = hostingView
        self.panel = panel

        // Dynamically expand and slide window as subfolders cascade open
        viewModel.$columns
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cols in
                guard let self = self, self.panel?.isVisible == true else { return }
                self.updateLayoutForColumns(columnCount: cols.count, animated: true)
            }
            .store(in: &cancellables)
    }

    public func show(at mouseLocation: CGPoint, isCopyMode: Bool) {
        guard let panel = panel else { return }

        logger.info("[QuiFi] Showing HUD panel at cursor: \(mouseLocation.x), \(mouseLocation.y)")
        self.initialMouseLocation = mouseLocation

        viewModel.reloadPinnedRoots()
        viewModel.isCopyMode = isCopyMode
        viewModel.clearHover()

        let screen = NSScreen.screens.first(where: { NSPointInRect(mouseLocation, $0.frame) }) ?? NSScreen.main
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        // Anchor position for column 0
        let initialWidth: CGFloat = 185 + 24
        var anchorX = mouseLocation.x + 18
        if anchorX + initialWidth > visible.maxX - 16 {
            anchorX = visible.maxX - 16 - initialWidth
        }
        if anchorX < visible.minX + 16 {
            anchorX = visible.minX + 16
        }
        self.anchoredOriginX = anchorX

        updateLayoutForColumns(columnCount: viewModel.columns.count, animated: false)

        panel.alphaValue = 0.0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1.0
        }
    }

    public func hide() {
        logger.info("[QuiFi] Hiding HUD panel")
        viewModel.clearHover()
        EventTapManager.shared.setHUDState(isShown: false)

        guard let panel = panel, panel.isVisible else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0.0
        }, completionHandler: { [weak panel] in
            panel?.orderOut(nil)
            panel?.alphaValue = 1.0
        })
    }

    public func updateModifier(isCopyMode: Bool) {
        viewModel.isCopyMode = isCopyMode
    }

    private func updateLayoutForColumns(columnCount: Int, animated: Bool) {
        guard let panel = panel else { return }

        let count = max(1, columnCount)
        let colWidth: CGFloat = 185
        let spacing: CGFloat = 10
        let horizontalPadding: CGFloat = 24
        let targetHeight: CGFloat = 330

        let targetWidth = (CGFloat(count) * colWidth) + (CGFloat(count - 1) * spacing) + horizontalPadding

        let screen = NSScreen.screens.first(where: { NSPointInRect(initialMouseLocation, $0.frame) }) ?? NSScreen.main
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        // Anchor the left side to anchoredOriginX so column 0 never moves!
        var originX = anchoredOriginX

        // Only shift the window left if expanding would physically go past the right screen boundary
        let maxRight = visible.maxX - 16
        if originX + targetWidth > maxRight {
            originX = maxRight - targetWidth
        }

        // Clamp to left screen boundary
        let minLeft = visible.minX + 16
        if originX < minLeft {
            originX = minLeft
        }

        var originY = initialMouseLocation.y - (targetHeight / 2)

        // Clamp to vertical screen boundaries
        if originY + targetHeight > visible.maxY - 12 {
            originY = visible.maxY - targetHeight - 12
        }
        if originY < visible.minY + 12 {
            originY = visible.minY + 12
        }

        let newFrame = NSRect(x: originX, y: originY, width: targetWidth, height: targetHeight)

        if animated {
            if newFrame.width >= panel.frame.width {
                // Expanding: instantly provide full runway so SwiftUI never centers or shifts left
                panel.setFrame(newFrame, display: true)
            } else {
                // Shrinking: animate smoothly back
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.32
                    context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.0, 0.2, 1.0)
                    panel.animator().setFrame(newFrame, display: true)
                }
            }
        } else {
            panel.setFrame(newFrame, display: true)
        }
    }

    private func handleDrop(urls: [URL], targetFolder: FolderNode) {
        let prefs = PreferencesStore.shared.preferences
        let isCopy = viewModel.isCopyMode

        logger.info("[QuiFi] Dropped \(urls.count) file(s) into folder: \(targetFolder.url.path)")

        if prefs.playFeedback {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }

        hide()

        Task { [weak self] in
            guard let self = self else { return }
            _ = await FileOrganizerService.shared.transferFiles(
                sources: urls,
                to: targetFolder.url,
                isCopy: isCopy,
                preferences: prefs,
                conflictPrompt: { source, existingDestination in
                    return await self.promptConflict(
                        source: source,
                        target: existingDestination,
                        preferences: prefs
                    )
                }
            )

            if prefs.playFeedback {
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            }
        }
    }

    @MainActor
    private func promptConflict(source: URL, target: URL, preferences: Preferences) async -> ConflictChoice {
        let previewURL = FileOrganizerService.shared.generateNonCollidingURL(
            for: target,
            format: preferences.renameFormat
        )

        return await withCheckedContinuation { continuation in
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 380, height: 260),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "QuiFi: Dateikonflikt"
            window.center()
            window.level = .floating

            let view = ConflictDialogView(
                sourceURL: source,
                targetURL: target,
                renamePreviewName: previewURL.lastPathComponent
            ) { [weak window] choice in
                window?.close()
                continuation.resume(returning: choice)
            }

            window.contentView = NSHostingView(rootView: view)
            self.conflictWindow = window
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
