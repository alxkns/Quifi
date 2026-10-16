import Foundation
import Combine
import AppKit

public struct FolderColumn: Identifiable, Equatable {
    public let id: String
    public let index: Int
    public let title: String
    public let folders: [FolderNode]

    public init(id: String, index: Int, title: String, folders: [FolderNode]) {
        self.id = id
        self.index = index
        self.title = title
        self.folders = folders
    }

    public static func == (lhs: FolderColumn, rhs: FolderColumn) -> Bool {
        lhs.id == rhs.id && lhs.folders == rhs.folders
    }
}

public final class CascadingFolderViewModel: ObservableObject {
    @Published public var columns: [FolderColumn] = []
    @Published public var selectedPath: [FolderNode] = []
    @Published public var hoveredTarget: FolderNode?
    @Published public var isCopyMode: Bool = false
    @Published public var isTransferring: Bool = false
    @Published public var feedbackMessage: String?
    public var onWillUpdateColumns: ((Int) -> Void)?

    private let scanner = FolderScanner.shared
    private let prefsStore = PreferencesStore.shared
    private var hoverTimer: Timer?

    public init() {
        reloadPinnedRoots()
    }

    public func reloadPinnedRoots() {
        let prefs = prefsStore.preferences
        let roots = prefs.pinnedFolders.compactMap { folder -> FolderNode? in
            guard folder.exists else { return nil }
            let hasSubs = scanner.hasSubfolders(at: folder.url, respectSystemHidden: prefs.respectSystemHiddenFiles)
            return FolderNode(
                name: folder.name,
                url: folder.url,
                iconName: folder.iconName,
                isPinnedRoot: true,
                depth: 0,
                hasSubfolders: hasSubs
            )
        }

        let fallbackRoots: [FolderNode]
        if roots.isEmpty {
            var fallback: [FolderNode] = []
            if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                let hasSubs = scanner.hasSubfolders(at: downloads, respectSystemHidden: prefs.respectSystemHiddenFiles)
                fallback.append(FolderNode(name: "Downloads", url: downloads, iconName: "arrow.down.circle.fill", isPinnedRoot: true, hasSubfolders: hasSubs))
            }
            if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let hasSubs = scanner.hasSubfolders(at: docs, respectSystemHidden: prefs.respectSystemHiddenFiles)
                fallback.append(FolderNode(name: "Documents", url: docs, iconName: "doc.fill", isPinnedRoot: true, hasSubfolders: hasSubs))
            }
            if let desk = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
                let hasSubs = scanner.hasSubfolders(at: desk, respectSystemHidden: prefs.respectSystemHiddenFiles)
                fallback.append(FolderNode(name: "Desktop", url: desk, iconName: "macwindow", isPinnedRoot: true, hasSubfolders: hasSubs))
            }
            fallbackRoots = fallback
        } else {
            fallbackRoots = roots
        }

        columns = [FolderColumn(id: "root", index: 0, title: "Favorites", folders: fallbackRoots)]
        selectedPath = []
        hoveredTarget = nil
    }

    public func hoverOver(node: FolderNode, atColumnIndex columnIndex: Int) {
        hoveredTarget = node

        // If already expanded at this depth, do not restart timer or re-expand
        if selectedPath.indices.contains(columnIndex), selectedPath[columnIndex].id == node.id {
            return
        }

        // Cancel previous pending hover
        hoverTimer?.invalidate()

        // Deliberate 220ms hover dwell: comfortable, prevents jumping when sweeping across rows
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.22, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.expandNode(node, atColumnIndex: columnIndex)
        }
    }

    public func expandNode(_ node: FolderNode, atColumnIndex columnIndex: Int) {
        let prefs = prefsStore.preferences
        let subfolders = node.hasSubfolders
            ? scanner.subfolders(
                at: node.url,
                depth: columnIndex + 1,
                respectSystemHidden: prefs.respectSystemHiddenFiles
            )
            : []

        // Truncate selected path to current column
        if selectedPath.count > columnIndex {
            selectedPath = Array(selectedPath.prefix(columnIndex))
        }
        selectedPath.append(node)

        // Truncate columns up to current column
        var newColumns = Array(columns.prefix(columnIndex + 1))
        if !subfolders.isEmpty {
            newColumns.append(FolderColumn(
                id: node.url.path,
                index: columnIndex + 1,
                title: node.name,
                folders: subfolders
            ))
        }

        // Notify HUDWindowController immediately so the window frame is sized before SwiftUI renders
        onWillUpdateColumns?(newColumns.count)
        self.columns = newColumns
    }

    public func clearHover() {
        hoverTimer?.invalidate()
        hoverTimer = nil
        hoveredTarget = nil
    }
}
