import Foundation
import Combine
import AppKit

public final class CascadingFolderViewModel: ObservableObject {
    @Published public var columns: [[FolderNode]] = []
    @Published public var selectedPath: [FolderNode] = []
    @Published public var hoveredTarget: FolderNode?
    @Published public var isCopyMode: Bool = false
    @Published public var isTransferring: Bool = false
    @Published public var feedbackMessage: String?

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
            return FolderNode(
                name: folder.name,
                url: folder.url,
                iconName: folder.iconName,
                isPinnedRoot: true,
                depth: 0
            )
        }
        if roots.isEmpty {
            var fallback: [FolderNode] = []
            if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                fallback.append(FolderNode(name: "Downloads", url: downloads, iconName: "arrow.down.circle.fill", isPinnedRoot: true))
            }
            if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                fallback.append(FolderNode(name: "Dokumente", url: docs, iconName: "doc.fill", isPinnedRoot: true))
            }
            if let desk = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
                fallback.append(FolderNode(name: "Schreibtisch", url: desk, iconName: "macwindow", isPinnedRoot: true))
            }
            columns = [fallback]
        } else {
            columns = [roots]
        }
        selectedPath = []
        hoveredTarget = nil
    }

    public func hoverOver(node: FolderNode, atColumnIndex columnIndex: Int) {
        hoveredTarget = node

        // Cancel previous timer
        hoverTimer?.invalidate()

        // Immediate or snappy 120ms expansion of child folders
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.expandNode(node, atColumnIndex: columnIndex)
        }
    }

    public func expandNode(_ node: FolderNode, atColumnIndex columnIndex: Int) {
        let prefs = prefsStore.preferences
        let subfolders = scanner.subfolders(
            at: node.url,
            depth: columnIndex + 1,
            respectSystemHidden: prefs.respectSystemHiddenFiles
        )

        // Truncate selected path to current column
        if selectedPath.count > columnIndex {
            selectedPath = Array(selectedPath.prefix(columnIndex))
        }
        selectedPath.append(node)

        // Truncate columns after current column
        var newColumns = Array(columns.prefix(columnIndex + 1))
        if !subfolders.isEmpty {
            newColumns.append(subfolders)
        }
        self.columns = newColumns
    }

    public func clearHover() {
        hoverTimer?.invalidate()
        hoverTimer = nil
        hoveredTarget = nil
    }
}
