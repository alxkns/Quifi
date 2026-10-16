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

        updateLayoutForColumns(columnCount: viewModel.columns.count, animated: false)

        panel.alphaValue = 1.0
        panel.orderFrontRegardless()
    }

    public func hide() {
        logger.info("[QuiFi] Hiding HUD panel")
        panel?.orderOut(nil)
        viewModel.clearHover()
        EventTapManager.shared.setHUDState(isShown: false)
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

        // Try placing the panel to the right of the initial mouse location
        var originX = initialMouseLocation.x + 18
        var originY = initialMouseLocation.y - (targetHeight / 2)

        // If the cascade grows beyond the right screen edge, smoothly shift it left
        let maxRight = visible.maxX - 16
        if originX + targetWidth > maxRight {
            originX = maxRight - targetWidth
        }

        // Clamp to left screen boundary
        let minLeft = visible.minX + 16
        if originX < minLeft {
            originX = minLeft
        }

        // Clamp to vertical screen boundaries
        if originY + targetHeight > visible.maxY - 12 {
            originY = visible.maxY - targetHeight - 12
        }
        if originY < visible.minY + 12 {
            originY = visible.minY + 12
        }

        let newFrame = NSRect(x: originX, y: originY, width: targetWidth, height: targetHeight)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrame(newFrame, display: true)
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
