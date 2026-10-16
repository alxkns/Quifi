import Foundation

public enum TriggerModifier: String, Codable, CaseIterable {
    case command = "⌘ Command"
    case option = "⌥ Option"
    case control = "⌃ Control"
    
    public var flagMask: UInt64 {
        switch self {
        case .command: return 0x00100000 // NSEvent.ModifierFlags.command
        case .option:  return 0x00080000 // NSEvent.ModifierFlags.option
        case .control: return 0x00040000 // NSEvent.ModifierFlags.control
        }
    }
}

public enum ConflictResolution: String, Codable, CaseIterable {
    case ask = "Nachfragen"
    case autoRename = "Automatisch umbenennen"
    case replace = "Überschreiben"
}

public enum RenameFormat: String, Codable, CaseIterable {
    case counter = "Zähler: {name}_{counter}"
    case counterParentheses = "Zähler: {name} ({counter})"
    case date = "Datum: {name}_{date}"
    case dateTime = "Datum & Zeit: {name}_{datetime}"
}

public struct Preferences: Codable, Equatable {
    public var pinnedFolders: [PinnedFolder]
    public var enableShakeTrigger: Bool
    public var shakeSensitivity: Double
    public var enableModifierTrigger: Bool
    public var triggerModifier: TriggerModifier
    public var copyModifier: TriggerModifier
    public var conflictResolution: ConflictResolution
    public var renameFormat: RenameFormat
    public var respectSystemHiddenFiles: Bool
    public var playFeedback: Bool

    public static let `default`: Preferences = {
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first

        var initialFolders: [PinnedFolder] = []
        if let docs = documents {
            initialFolders.append(PinnedFolder(name: "Dokumente", url: docs, iconName: "doc.fill"))
        }
        if let down = downloads {
            initialFolders.append(PinnedFolder(name: "Downloads", url: down, iconName: "arrow.down.circle.fill"))
        }
        if let desk = desktop {
            initialFolders.append(PinnedFolder(name: "Schreibtisch", url: desk, iconName: "macwindow"))
        }

        return Preferences(
            pinnedFolders: initialFolders,
            enableShakeTrigger: true,
            shakeSensitivity: 35.0,
            enableModifierTrigger: true,
            triggerModifier: .command,
            copyModifier: .option,
            conflictResolution: .ask,
            renameFormat: .counter,
            respectSystemHiddenFiles: true,
            playFeedback: true
        )
    }()
}
