import AppKit
import QuiFiKit

final class AppDelegate: NSObject, NSApplicationDelegate, EventTapManagerDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as menu bar accessory (no Dock icon)
        NSApp.setActivationPolicy(.accessory)

        // Setup status item menu
        MenuBarController.shared.setup()

        // Setup Event Tap
        EventTapManager.shared.delegate = self
        EventTapManager.shared.start()

        // Check accessibility
        if !AccessibilityHelper.isAccessibilityGranted {
            print("[QuiFi] Accessibility permissions needed. Prompting user...")
            SettingsWindowController.shared.show()
            _ = AccessibilityHelper.requestAccessibility(prompt: true)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        SettingsWindowController.shared.show()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        EventTapManager.shared.stop()
    }

    // MARK: - EventTapManagerDelegate
    func eventTapTriggeredHUD(at location: CGPoint, isCopyModifierActive: Bool) {
        HUDWindowController.shared.show(at: location, isCopyMode: isCopyModifierActive)
    }

    func eventTapDidEndDrag() {
        // Only hide if not in the middle of a conflict dialog or active drop
        // HUDWindowController will hide on drop; if drop was outside, close here
        HUDWindowController.shared.hide()
    }

    func eventTapModifierChanged(isCopyModifierActive: Bool) {
        HUDWindowController.shared.updateModifier(isCopyMode: isCopyModifierActive)
    }
}
