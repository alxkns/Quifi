import Foundation

public enum ConflictChoice {
    case replace
    case rename
    case skip
}

public struct TransferResult {
    public let sourceURL: URL
    public let destinationURL: URL
    public let wasCopied: Bool
    public let success: Bool
    public let error: Error?
}

public final class FileOrganizerService {
    public static let shared = FileOrganizerService()

    public init() {}

    /// Calculates a non-colliding destination URL based on the user's rename format rule.
    public func generateNonCollidingURL(
        for originalDestination: URL,
        format: RenameFormat,
        date: Date = Date()
    ) -> URL {
        let fileManager = FileManager.default
        let directory = originalDestination.deletingLastPathComponent()
        let filename = originalDestination.deletingPathExtension().lastPathComponent
        let ext = originalDestination.pathExtension
        let dotExt = ext.isEmpty ? "" : ".\(ext)"

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "de_DE")

        switch format {
        case .counter:
            var counter = 1
            while true {
                let candidateName = "\(filename)_\(counter)\(dotExt)"
                let candidateURL = directory.appendingPathComponent(candidateName)
                if !fileManager.fileExists(atPath: candidateURL.path) {
                    return candidateURL
                }
                counter += 1
            }

        case .counterParentheses:
            var counter = 1
            while true {
                let candidateName = "\(filename) (\(counter))\(dotExt)"
                let candidateURL = directory.appendingPathComponent(candidateName)
                if !fileManager.fileExists(atPath: candidateURL.path) {
                    return candidateURL
                }
                counter += 1
            }

        case .date:
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateStr = dateFormatter.string(from: date)
            let baseWithDate = "\(filename)_\(dateStr)"
            let firstCandidate = directory.appendingPathComponent("\(baseWithDate)\(dotExt)")
            if !fileManager.fileExists(atPath: firstCandidate.path) {
                return firstCandidate
            }
            var counter = 1
            while true {
                let candidateName = "\(baseWithDate)_\(counter)\(dotExt)"
                let candidateURL = directory.appendingPathComponent(candidateName)
                if !fileManager.fileExists(atPath: candidateURL.path) {
                    return candidateURL
                }
                counter += 1
            }

        case .dateTime:
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateStr = dateFormatter.string(from: date)
            let baseWithDate = "\(filename)_\(dateStr)"
            let firstCandidate = directory.appendingPathComponent("\(baseWithDate)\(dotExt)")
            if !fileManager.fileExists(atPath: firstCandidate.path) {
                return firstCandidate
            }
            var counter = 1
            while true {
                let candidateName = "\(baseWithDate)_\(counter)\(dotExt)"
                let candidateURL = directory.appendingPathComponent(candidateName)
                if !fileManager.fileExists(atPath: candidateURL.path) {
                    return candidateURL
                }
                counter += 1
            }
        }
    }

    /// Moves or copies files into the target directory, handling conflicts appropriately.
    public func transferFiles(
        sources: [URL],
        to destinationDirectory: URL,
        isCopy: Bool,
        preferences: Preferences,
        conflictPrompt: ((_ source: URL, _ existingDestination: URL) async -> ConflictChoice)? = nil
    ) async -> [TransferResult] {
        let fileManager = FileManager.default
        var results: [TransferResult] = []

        for source in sources {
            let targetURL = destinationDirectory.appendingPathComponent(source.lastPathComponent)
            var finalDestination = targetURL

            if fileManager.fileExists(atPath: targetURL.path) {
                var choice: ConflictChoice

                switch preferences.conflictResolution {
                case .autoRename:
                    choice = .rename
                case .replace:
                    choice = .replace
                case .ask:
                    if let prompt = conflictPrompt {
                        choice = await prompt(source, targetURL)
                    } else {
                        choice = .rename
                    }
                }

                switch choice {
                case .skip:
                    results.append(TransferResult(
                        sourceURL: source,
                        destinationURL: targetURL,
                        wasCopied: isCopy,
                        success: false,
                        error: nil
                    ))
                    continue

                case .replace:
                    do {
                        try fileManager.removeItem(at: targetURL)
                    } catch {
                        results.append(TransferResult(
                            sourceURL: source,
                            destinationURL: targetURL,
                            wasCopied: isCopy,
                            success: false,
                            error: error
                        ))
                        continue
                    }

                case .rename:
                    finalDestination = generateNonCollidingURL(for: targetURL, format: preferences.renameFormat)
                }
            }

            do {
                if isCopy {
                    try fileManager.copyItem(at: source, to: finalDestination)
                } else {
                    try fileManager.moveItem(at: source, to: finalDestination)
                }
                results.append(TransferResult(
                    sourceURL: source,
                    destinationURL: finalDestination,
                    wasCopied: isCopy,
                    success: true,
                    error: nil
                ))
            } catch {
                results.append(TransferResult(
                    sourceURL: source,
                    destinationURL: finalDestination,
                    wasCopied: isCopy,
                    success: false,
                    error: error
                ))
            }
        }

        return results
    }
}
