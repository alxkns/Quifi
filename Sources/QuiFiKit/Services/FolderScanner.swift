import Foundation

public final class FolderScanner {
    public static let shared = FolderScanner()

    public init() {}

    /// Checks whether macOS Finder is configured to display hidden files.
    public var isFinderShowingHiddenFiles: Bool {
        if let finderDefaults = UserDefaults(suiteName: "com.apple.finder") {
            if let val = finderDefaults.object(forKey: "AppleShowAllFiles") {
                if let boolVal = val as? Bool {
                    return boolVal
                }
                if let strVal = val as? String {
                    return strVal.lowercased() == "yes" || strVal == "1" || strVal.lowercased() == "true"
                }
                if let numVal = val as? NSNumber {
                    return numVal.boolValue
                }
            }
        }
        return false
    }

    /// Efficiently checks whether a directory contains at least one child directory.
    public func hasSubfolders(at url: URL, respectSystemHidden: Bool = true) -> Bool {
        let fileManager = FileManager.default
        let showHidden = respectSystemHidden ? isFinderShowingHiddenFiles : false

        let keys: [URLResourceKey] = [.isDirectoryKey, .isHiddenKey, .isPackageKey]
        let options: FileManager.DirectoryEnumerationOptions = showHidden ? [] : [.skipsHiddenFiles]

        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: keys,
            options: options
        ) else {
            return false
        }

        for itemURL in contents {
            if !showHidden && itemURL.lastPathComponent.hasPrefix(".") {
                continue
            }

            guard let resourceValues = try? itemURL.resourceValues(forKeys: Set(keys)),
                  let isDir = resourceValues.isDirectory, isDir else {
                continue
            }

            if let isPackage = resourceValues.isPackage, isPackage {
                continue
            }

            if !showHidden, let isHidden = resourceValues.isHidden, isHidden {
                continue
            }

            return true
        }

        return false
    }

    /// Fetches all immediate child directories for a given URL.
    public func subfolders(at url: URL, depth: Int = 0, respectSystemHidden: Bool = true) -> [FolderNode] {
        let fileManager = FileManager.default
        let showHidden = respectSystemHidden ? isFinderShowingHiddenFiles : false

        let keys: [URLResourceKey] = [.isDirectoryKey, .isHiddenKey, .isPackageKey]
        let options: FileManager.DirectoryEnumerationOptions = showHidden ? [] : [.skipsHiddenFiles]

        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: keys,
            options: options
        ) else {
            return []
        }

        var folders: [FolderNode] = []

        for itemURL in contents {
            // Ignore hidden items starting with dot if not showing hidden
            if !showHidden && itemURL.lastPathComponent.hasPrefix(".") {
                continue
            }

            guard let resourceValues = try? itemURL.resourceValues(forKeys: Set(keys)),
                  let isDir = resourceValues.isDirectory, isDir else {
                continue
            }

            if let isPackage = resourceValues.isPackage, isPackage {
                continue
            }

            if !showHidden, let isHidden = resourceValues.isHidden, isHidden {
                continue
            }

            let hasSubs = hasSubfolders(at: itemURL, respectSystemHidden: respectSystemHidden)

            folders.append(
                FolderNode(
                    name: itemURL.lastPathComponent,
                    url: itemURL,
                    iconName: "folder.fill",
                    isPinnedRoot: false,
                    depth: depth,
                    hasSubfolders: hasSubs
                )
            )
        }

        // Natural sort order (e.g. 2024, 2025, 2026 or 1_Jan, 2_Feb...)
        return folders.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
