import Foundation

public struct PinnedFolder: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var url: URL
    public var iconName: String
    public var bookmarkData: Data?

    public init(id: UUID = UUID(), name: String, url: URL, iconName: String = "folder.fill", bookmarkData: Data? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.iconName = iconName
        self.bookmarkData = bookmarkData
    }

    public var exists: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
}
