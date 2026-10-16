import Testing
import Foundation
@testable import QuiFiKit

struct QuiFiTests {
    @Test func renameRuleCounter() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("QuiFiTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = FileOrganizerService()
        let file = tempDir.appendingPathComponent("Lohnabrechnung.pdf")
        FileManager.default.createFile(atPath: file.path, contents: "dummy".data(using: .utf8))

        let candidate1 = service.generateNonCollidingURL(for: file, format: .counter)
        #expect(candidate1.lastPathComponent == "Lohnabrechnung_1.pdf")

        // Create the candidate1 file and check for candidate2
        FileManager.default.createFile(atPath: candidate1.path, contents: "dummy".data(using: .utf8))
        let candidate2 = service.generateNonCollidingURL(for: file, format: .counter)
        #expect(candidate2.lastPathComponent == "Lohnabrechnung_2.pdf")
    }

    @Test func renameRuleCounterParentheses() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("QuiFiTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = FileOrganizerService()
        let file = tempDir.appendingPathComponent("Lohnabrechnung.pdf")
        FileManager.default.createFile(atPath: file.path, contents: "dummy".data(using: .utf8))

        let candidate = service.generateNonCollidingURL(for: file, format: .counterParentheses)
        #expect(candidate.lastPathComponent == "Lohnabrechnung (1).pdf")
    }

    @Test func renameRuleDate() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("QuiFiTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = FileOrganizerService()
        let file = tempDir.appendingPathComponent("Bericht.docx")
        FileManager.default.createFile(atPath: file.path, contents: "dummy".data(using: .utf8))

        let fixedDate = Date(timeIntervalSince1970: 1776337200) // approx 2026-04-16
        let candidate = service.generateNonCollidingURL(for: file, format: .date, date: fixedDate)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: fixedDate)

        #expect(candidate.lastPathComponent == "Bericht_\(dateStr).docx")
    }

    @Test func shakeDetectorTrigger() {
        let detector = ShakeDetector(sensitivity: 20.0)
        detector.cooldown = 0.0
        var shakeTriggered = false
        detector.onShakeDetected = {
            shakeTriggered = true
        }

        let now = Date()
        // Simulate rapid back-and-forth movement:
        detector.addPoint(x: 0, timestamp: now)
        detector.addPoint(x: 50, timestamp: now.addingTimeInterval(0.05))
        detector.addPoint(x: 0, timestamp: now.addingTimeInterval(0.10))
        detector.addPoint(x: 50, timestamp: now.addingTimeInterval(0.15))
        detector.addPoint(x: 0, timestamp: now.addingTimeInterval(0.20))

        #expect(shakeTriggered)
    }

    @Test func folderScannerNaturalSort() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("QuiFiTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let scanner = FolderScanner()
        let folder2024 = tempDir.appendingPathComponent("2024")
        let folder2025 = tempDir.appendingPathComponent("2025")
        let folder2026 = tempDir.appendingPathComponent("2026")
        let hiddenFolder = tempDir.appendingPathComponent(".hidden")

        try FileManager.default.createDirectory(at: folder2025, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: folder2024, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: folder2026, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: hiddenFolder, withIntermediateDirectories: true)

        let subfolders = scanner.subfolders(at: tempDir, depth: 0, respectSystemHidden: false)
        let names = subfolders.map(\.name)

        #expect(names == ["2024", "2025", "2026"])
        #expect(!names.contains(".hidden"))
    }

    @Test func versionComparison() {
        #expect(UpdateManager.isVersion("v1.0.1", newerThan: "1.0.0"))
        #expect(UpdateManager.isVersion("1.1.0", newerThan: "1.0.9"))
        #expect(UpdateManager.isVersion("2.0.0", newerThan: "1.9.9"))
        #expect(!UpdateManager.isVersion("1.0.0", newerThan: "1.0.0"))
        #expect(!UpdateManager.isVersion("1.0.0", newerThan: "1.0.1"))
        #expect(!UpdateManager.isVersion("0.9.9", newerThan: "1.0.0"))
    }

    @Test func menuBarIcons() {
        for style in MenuBarIconStyle.allCases {
            let icon = MenuBarIconHelper.icon(for: style)
            #expect(icon.isTemplate)
            #expect(icon.size.width > 0)
        }
    }

    @Test func preferencesBackwardCompatibility() throws {
        // Old JSON without menuBarIconStyle
        let legacyJSON = """
        {
            "pinnedFolders": [],
            "enableShakeTrigger": true,
            "shakeSensitivity": 30.0,
            "enableModifierTrigger": true,
            "triggerModifier": "⌘ Command",
            "copyModifier": "⌥ Option",
            "conflictResolution": "Ask what to do",
            "renameFormat": "Counter: {name}_{counter}",
            "respectSystemHiddenFiles": true,
            "playFeedback": true,
            "autoCheckForUpdates": true
        }
        """.data(using: .utf8)!

        let prefs = try JSONDecoder().decode(Preferences.self, from: legacyJSON)
        #expect(prefs.menuBarIconStyle == .quifiLightning)
        #expect(prefs.shakeSensitivity == 30.0)
    }
}
