import AppKit
import SwiftUI

public final class HUDWindowController: NSObject {
    public static let shared = HUDWindowController()

    private var panel: NSPanel?
    public let viewModel = CascadingFolderViewModel()
    private var conflictWindow: NSWindow?

    public override init() {
        super.init()
        setupPanel()
    }

    private func setupPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 260),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.isFloatingPanel = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let rootView = CascadingFolderView(viewModel: viewModel) { [weak self] urls, targetFolder in
            self?.handleDrop(urls: urls, targetFolder: targetFolder)
        }

        let hostingView = NSHostingView(rootView: rootView)
        panel.contentView = hostingView
        self.panel = panel
    }

    public func show(at mouseLocation: CGPoint, isCopyMode: Bool) {
        guard let panel = panel else { return }

        viewModel.reloadPinnedRoots()
        viewModel.isCopyMode = isCopyMode
        viewModel.clearHover()

        // Size to fit content
        panel.layoutIfNeeded()
        let size = panel.frame.size

        // Position slightly offset from cursor so it doesn't immediately drop under cursor
        var origin = CGPoint(x: mouseLocation.x + 16, y: mouseLocation.y - (size.height / 2))

        // Screen boundary protection
        if let screen = NSScreen.screens.first(where: { NSPointInRect(mouseLocation, $0.frame) }) ?? NSScreen.main {
            let visible = screen.visibleFrame
            if origin.x + size.width > visible.maxX {
                origin.x = mouseLocation.x - size.width - 16
            }
            if origin.x < visible.minX {
                origin.x = visible.minX + 10
            }
            if origin.y + size.height > visible.maxY {
                origin.y = visible.maxY - size.height - 10
            }
            if origin.y < visible.minY {
                origin.y = visible.minY + 10
            }
        }

        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()
    }

    public func hide() {
        panel?.orderOut(nil)
        viewModel.clearHover()
        EventTapManager.shared.setHUDState(isShown: false)
    }

    public func updateModifier(isCopyMode: Bool) {
        viewModel.isCopyMode = isCopyMode
    }

    private func handleDrop(urls: [URL], targetFolder: FolderNode) {
        let prefs = PreferencesStore.shared.preferences
        let isCopy = viewModel.isCopyMode

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
            window.title = "QuiFi: File Conflict"
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
