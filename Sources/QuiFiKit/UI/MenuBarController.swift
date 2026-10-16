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
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 440),
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

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "folder.badge.gearshape",
                accessibilityDescription: "QuiFi - Quick File Organizer"
            )
        }

        self.statusItem = statusItem
        updateMenu()
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

        statusItem?.menu = menu
    }

    @objc private func testHUD() {
        let mouseLoc = NSEvent.mouseLocation
        HUDWindowController.shared.show(at: mouseLoc, isCopyMode: false)
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func requestAccessibility() {
        AccessibilityHelper.openSystemAccessibilityPreferences()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
