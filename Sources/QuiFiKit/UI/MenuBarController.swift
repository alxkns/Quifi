import AppKit
import SwiftUI

public final class SettingsWindowController: NSObject {
    public static let shared = SettingsWindowController()
    private var window: NSWindow?

    public func show() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "QuiFi Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView())

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

public final class MenuBarController: NSObject {
    public static let shared = MenuBarController()

    private var statusItem: NSStatusItem?

    public func setup() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem

        updateIcon()
        updateMenu()
    }

    public func updateIcon() {
        let style = PreferencesStore.shared.preferences.menuBarIconStyle
        if let button = statusItem?.button {
            button.image = MenuBarIconHelper.icon(for: style)
        }
    }

    public func updateMenu() {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "QuiFi - Quick File Organizer", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        let testItem = NSMenuItem(
            title: "Open HUD Preview",
            action: #selector(testHUD),
            keyEquivalent: "t"
        )
        testItem.target = self
        menu.addItem(testItem)

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        if UpdateManager.shared.updateAvailable, let release = UpdateManager.shared.latestRelease {
            let updateItem = NSMenuItem(
                title: "✨ Update to \(release.tagName) available!",
                action: #selector(openSettings),
                keyEquivalent: "u"
            )
            updateItem.target = self
            menu.addItem(updateItem)
        } else {
            let updateItem = NSMenuItem(
                title: "Check for Updates…",
                action: #selector(checkForUpdatesMenu),
                keyEquivalent: ""
            )
            updateItem.target = self
            menu.addItem(updateItem)
        }

        menu.addItem(NSMenuItem.separator())

        let accessStatus = AccessibilityHelper.isAccessibilityGranted
        let accessItem = NSMenuItem(
            title: accessStatus ? "✓ Accessibility Enabled" : "⚠️ Enable Accessibility…",
            action: accessStatus ? nil : #selector(requestAccessibility),
            keyEquivalent: ""
        )
        accessItem.target = self
        menu.addItem(accessItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit QuiFi",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        menu.delegate = self
        statusItem?.menu = menu
    }

    @objc private func testHUD() {
        let mouseLoc = NSEvent.mouseLocation
        HUDWindowController.shared.show(at: mouseLoc, isCopyMode: false)
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func checkForUpdatesMenu() {
        SettingsWindowController.shared.show()
        Task {
            await UpdateManager.shared.checkForUpdates(manual: true)
        }
    }

    @objc private func requestAccessibility() {
        AccessibilityHelper.openSystemAccessibilityPreferences()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

extension MenuBarController: NSMenuDelegate {
    public func menuWillOpen(_ menu: NSMenu) {
        if AccessibilityHelper.isAccessibilityGranted {
            EventTapManager.shared.start()
        }
        updateMenu()
    }
}

