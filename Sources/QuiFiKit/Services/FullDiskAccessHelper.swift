import Foundation
import AppKit

public final class FullDiskAccessHelper {
    /// Checks whether QuiFi has Full Disk Access (Festplattenvollzugriff).
    /// When granted, macOS allows reading and writing to all directories (Downloads, Documents, Desktop,
    /// external drives, user folders) without prompting for individual per-folder permissions.
    public static var isFullDiskAccessGranted: Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let testPath = home.appendingPathComponent("Library/Safari").path
        return FileManager.default.isReadableFile(atPath: testPath)
    }

    public static func openFullDiskAccessPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
