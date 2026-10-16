import Foundation
import AppKit
import Combine
import os.log

public struct GitHubAsset: Codable {
    public let name: String
    public let browserDownloadUrl: String

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
    }
}

public struct GitHubRelease: Codable {
    public let tagName: String
    public let name: String?
    public let body: String?
    public let htmlUrl: String
    public let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case assets
    }
}

public final class UpdateManager: ObservableObject {
    public static let shared = UpdateManager()
    private let logger = Logger(subsystem: "org.quifi.app", category: "UpdateManager")

    @Published public var isChecking: Bool = false
    @Published public var isUpdating: Bool = false
    @Published public var updateAvailable: Bool = false
    @Published public var latestRelease: GitHubRelease?
    @Published public var downloadProgress: Double = 0.0
    @Published public var statusMessage: String = ""

    private var dailyTimer: Timer?
    private let repoAPIURL = URL(string: "https://api.github.com/repos/alxkns/Quifi/releases/latest")!

    public var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    public init() {
        startDailyTimer()
    }

    public func startDailyTimer() {
        dailyTimer?.invalidate()

        // Daily check timer (24 hours = 86400 seconds)
        dailyTimer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let prefs = PreferencesStore.shared.preferences
            if prefs.autoCheckForUpdates {
                Task {
                    await self.checkForUpdates(manual: false)
                }
            }
        }

        // On launch check if last check was > 24 hours ago
        let prefs = PreferencesStore.shared.preferences
        if prefs.autoCheckForUpdates {
            if let lastCheck = prefs.lastUpdateCheck {
                if Date().timeIntervalSince(lastCheck) > 86400 {
                    Task {
                        await checkForUpdates(manual: false)
                    }
                }
            } else {
                Task {
                    await checkForUpdates(manual: false)
                }
            }
        }
    }

    /// Checks whether candidateVersion is newer than currentVersion using semantic versioning.
    public static func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        let cleanCandidate = candidate.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let cleanCurrent = current.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))

        let candParts = cleanCandidate.split(separator: ".").compactMap { Int($0) }
        let currParts = cleanCurrent.split(separator: ".").compactMap { Int($0) }

        let maxCount = max(candParts.count, currParts.count)
        for i in 0..<maxCount {
            let c = i < candParts.count ? candParts[i] : 0
            let cur = i < currParts.count ? currParts[i] : 0
            if c > cur { return true }
            if c < cur { return false }
        }
        return false
    }

    @MainActor
    public func checkForUpdates(manual: Bool = false) async {
        guard !isChecking else { return }
        isChecking = true
        statusMessage = "Prüfe auf Updates…"

        defer {
            isChecking = false
            PreferencesStore.shared.preferences.lastUpdateCheck = Date()
        }

        do {
            var request = URLRequest(url: repoAPIURL)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            request.setValue("QuiFi-Updater", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 15.0

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                if manual {
                    statusMessage = "Keine Update-Informationen gefunden."
                }
                return
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            self.latestRelease = release

            if Self.isVersion(release.tagName, newerThan: currentVersion) {
                self.updateAvailable = true
                self.statusMessage = "Neues Update verfügbar: \(release.tagName)!"
                logger.info("[QuiFi] New update available: \(release.tagName)")
                
                // If checking manually or in background, update status bar menu
                DispatchQueue.main.async {
                    MenuBarController.shared.updateMenu()
                }
            } else {
                self.updateAvailable = false
                self.statusMessage = "QuiFi ist auf dem neuesten Stand (v\(currentVersion))."
            }
        } catch {
            logger.error("[QuiFi] Update check error: \(error.localizedDescription)")
            if manual {
                statusMessage = "Fehler beim Prüfen: \(error.localizedDescription)"
            }
        }
    }

    @MainActor
    public func downloadAndInstallUpdate() async {
        guard let release = latestRelease, !isUpdating else { return }
        guard let asset = release.assets.first(where: { $0.name.hasSuffix(".dmg") })
                ?? release.assets.first(where: { $0.name.hasSuffix(".zip") }) else {
            statusMessage = "Keine passende Installationsdatei im Release gefunden."
            return
        }

        guard let downloadURL = URL(string: asset.browserDownloadUrl) else { return }

        isUpdating = true
        statusMessage = "Lade \(asset.name) herunter…"
        downloadProgress = 0.1

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("QuiFi_Update_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let destinationFile = tempDir.appendingPathComponent(asset.name)

        do {
            let (tempLocalURL, _) = try await URLSession.shared.download(from: downloadURL)
            try FileManager.default.moveItem(at: tempLocalURL, to: destinationFile)
            downloadProgress = 0.7
            statusMessage = "Installiere Update…"

            if asset.name.hasSuffix(".dmg") {
                try installFromDMG(dmgPath: destinationFile, tempDir: tempDir)
            } else {
                try installFromZip(zipPath: destinationFile, tempDir: tempDir)
            }

            downloadProgress = 1.0
            statusMessage = "Update erfolgreich! QuiFi wird neu gestartet…"

            relaunchApp()
        } catch {
            logger.error("[QuiFi] Install failed: \(error.localizedDescription)")
            statusMessage = "Installation fehlgeschlagen: \(error.localizedDescription)"
            isUpdating = false
        }
    }

    private func installFromDMG(dmgPath: URL, tempDir: URL) throws {
        let mountPoint = tempDir.appendingPathComponent("mount")
        try? FileManager.default.createDirectory(at: mountPoint, withIntermediateDirectories: true)

        let attachProcess = Process()
        attachProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        attachProcess.arguments = ["attach", dmgPath.path, "-mountpoint", mountPoint.path, "-nobrowse", "-quiet"]
        try attachProcess.run()
        attachProcess.waitUntilExit()

        defer {
            let detachProcess = Process()
            detachProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            detachProcess.arguments = ["detach", mountPoint.path, "-quiet"]
            try? detachProcess.run()
            detachProcess.waitUntilExit()
        }

        let appInDMG = mountPoint.appendingPathComponent("QuiFi.app")
        let targetAppURL = URL(fileURLWithPath: "/Applications/QuiFi.app")

        if FileManager.default.fileExists(atPath: appInDMG.path) {
            let backupURL = tempDir.appendingPathComponent("QuiFi_Old.app")
            if FileManager.default.fileExists(atPath: targetAppURL.path) {
                try? FileManager.default.moveItem(at: targetAppURL, to: backupURL)
            }
            try FileManager.default.copyItem(at: appInDMG, to: targetAppURL)
            
            // Remove quarantine attribute
            let xattrProcess = Process()
            xattrProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
            xattrProcess.arguments = ["-cr", targetAppURL.path]
            try? xattrProcess.run()
            xattrProcess.waitUntilExit()
        } else {
            throw NSError(domain: "QuiFiUpdate", code: 404, userInfo: [NSLocalizedDescriptionKey: "QuiFi.app im Disk-Image nicht gefunden."])
        }
    }

    private func installFromZip(zipPath: URL, tempDir: URL) throws {
        let unzipDir = tempDir.appendingPathComponent("extracted")
        try? FileManager.default.createDirectory(at: unzipDir, withIntermediateDirectories: true)

        let unzipProcess = Process()
        unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        unzipProcess.arguments = ["-xk", zipPath.path, unzipDir.path]
        try unzipProcess.run()
        unzipProcess.waitUntilExit()

        let appInZip = unzipDir.appendingPathComponent("QuiFi.app")
        let targetAppURL = URL(fileURLWithPath: "/Applications/QuiFi.app")

        if FileManager.default.fileExists(atPath: appInZip.path) {
            let backupURL = tempDir.appendingPathComponent("QuiFi_Old.app")
            if FileManager.default.fileExists(atPath: targetAppURL.path) {
                try? FileManager.default.moveItem(at: targetAppURL, to: backupURL)
            }
            try FileManager.default.copyItem(at: appInZip, to: targetAppURL)

            let xattrProcess = Process()
            xattrProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
            xattrProcess.arguments = ["-cr", targetAppURL.path]
            try? xattrProcess.run()
            xattrProcess.waitUntilExit()
        } else {
            throw NSError(domain: "QuiFiUpdate", code: 404, userInfo: [NSLocalizedDescriptionKey: "QuiFi.app im Zip-Archiv nicht gefunden."])
        }
    }

    private func relaunchApp() {
        let appURL = URL(fileURLWithPath: "/Applications/QuiFi.app")
        let script = "sleep 0.8 && open \"\(appURL.path)\""

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", script]
        try? process.run()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApp.terminate(nil)
        }
    }
}
