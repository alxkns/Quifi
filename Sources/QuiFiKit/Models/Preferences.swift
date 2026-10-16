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
    case ask = "Ask what to do"
    case autoRename = "Automatically rename"
    case replace = "Overwrite"

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "Nachfragen", "Ask", "Ask what to do":
            self = .ask
        case "Automatisch umbenennen", "Auto rename", "Automatically rename":
            self = .autoRename
        case "Überschreiben", "Overwrite", "Replace":
            self = .replace
        default:
            self = .ask
        }
    }
}

public enum RenameFormat: String, Codable, CaseIterable {
    case counter = "Counter: {name}_{counter}"
    case counterParentheses = "Counter: {name} ({counter})"
    case date = "Date: {name}_{date}"
    case dateTime = "Date & Time: {name}_{datetime}"

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "Zähler: {name}_{counter}", "Counter: {name}_{counter}":
            self = .counter
        case "Zähler: {name} ({counter})", "Counter: {name} ({counter})":
            self = .counterParentheses
        case "Datum: {name}_{date}", "Date: {name}_{date}":
            self = .date
        case "Datum & Zeit: {name}_{datetime}", "Date & Time: {name}_{datetime}":
            self = .dateTime
        default:
            self = .counter
        }
    }
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
            let name = FileManager.default.displayName(atPath: docs.path)
            initialFolders.append(PinnedFolder(name: name, url: docs, iconName: "doc.fill"))
        }
        if let down = downloads {
            let name = FileManager.default.displayName(atPath: down.path)
            initialFolders.append(PinnedFolder(name: name, url: down, iconName: "arrow.down.circle.fill"))
        }
        if let desk = desktop {
            let name = FileManager.default.displayName(atPath: desk.path)
            initialFolders.append(PinnedFolder(name: name, url: desk, iconName: "macwindow"))
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
