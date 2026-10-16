import Foundation
import AppKit

public struct DragPasteboardHelper {
    public static let fileTypeIdentifiers: Set<String> = [
        NSPasteboard.PasteboardType.fileURL.rawValue, // "public.file-url"
        "NSFilenamesPboardType",
        "com.apple.finder.node",
        "codeeditors.file-urls"
    ]

    public static let promiseTypeIdentifiers: Set<String> = [
        "com.apple.pasteboard.promised-file-url",
        "com.apple.mac.promised-file-url",
        "com.apple.pasteboard.promised-file-content-type",
        "NSFilesPromisePboardType",
        "kPasteboardTypeFilePromiseContent"
    ]

    /// Returns true if the given pasteboard currently contains file URLs or promised files.
    public static func pasteboardContainsFiles(_ pasteboard: NSPasteboard = NSPasteboard(name: .drag)) -> Bool {
        // 1. Direct check: canReadObject for file URLs only
        if pasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) {
            return true
        }

        // 2. Check for standard file URL pasteboard types or promised files
        if let types = pasteboard.types {
            if types.contains(where: { fileTypeIdentifiers.contains($0.rawValue) }) {
                return true
            }
            if types.contains(where: { promiseTypeIdentifiers.contains($0.rawValue) }) {
                return true
            }
        }

        // 3. Fallback for older file paths array format
        if let files = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String], !files.isEmpty {
            return true
        }

        // 4. Check individual pasteboard items for file URL representations
        if let items = pasteboard.pasteboardItems {
            for item in items {
                for type in item.types {
                    if fileTypeIdentifiers.contains(type.rawValue) || promiseTypeIdentifiers.contains(type.rawValue) {
                        return true
                    }
                }
                if let urlString = item.string(forType: .fileURL) ?? item.string(forType: .URL),
                   let url = URL(string: urlString), url.isFileURL {
                    return true
                }
            }
        }

        return false
    }
}
