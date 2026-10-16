import Foundation
import Combine

public final class PreferencesStore: ObservableObject {
    public static let shared = PreferencesStore()
    private let key = "org.quifi.preferences"

    @Published public var preferences: Preferences {
        didSet {
            save()
        }
    }

    public init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Preferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = .default
        }
    }

    public func save() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    public func addPinnedFolder(url: URL, customName: String? = nil, iconName: String = "folder.fill") {
        let name = customName ?? url.lastPathComponent
        let bookmark = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        let folder = PinnedFolder(name: name, url: url, iconName: iconName, bookmarkData: bookmark)
        if !preferences.pinnedFolders.contains(where: { $0.url.path == url.path }) {
            preferences.pinnedFolders.append(folder)
        }
    }

    public func removePinnedFolder(at offsets: IndexSet) {
        preferences.pinnedFolders.remove(atOffsets: offsets)
    }

    public func removePinnedFolder(id: UUID) {
        preferences.pinnedFolders.removeAll { $0.id == id }
    }

    public func movePinnedFolder(fromOffsets source: IndexSet, toOffset destination: Int) {
        preferences.pinnedFolders.move(fromOffsets: source, toOffset: destination)
    }
}
