import Foundation

public struct FolderNode: Identifiable, Hashable {
    public var id: String { url.path }
    public let name: String
    public let url: URL
    public let iconName: String
    public let isPinnedRoot: Bool
    public let depth: Int
    public let hasSubfolders: Bool

    public init(
        name: String,
        url: URL,
        iconName: String = "folder.fill",
        isPinnedRoot: Bool = false,
        depth: Int = 0,
        hasSubfolders: Bool = false
    ) {
        self.name = name
        self.url = url
        self.iconName = iconName
        self.isPinnedRoot = isPinnedRoot
        self.depth = depth
        self.hasSubfolders = hasSubfolders
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(url.path)
    }

    public static func == (lhs: FolderNode, rhs: FolderNode) -> Bool {
        lhs.url.path == rhs.url.path && lhs.hasSubfolders == rhs.hasSubfolders
    }
}
