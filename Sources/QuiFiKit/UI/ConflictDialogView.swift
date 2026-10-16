import SwiftUI
import AppKit

public struct ConflictDialogView: View {
    let sourceURL: URL
    let targetURL: URL
    let renamePreviewName: String
    let onDecision: (ConflictChoice) -> Void

    public init(
        sourceURL: URL,
        targetURL: URL,
        renamePreviewName: String,
        onDecision: @escaping (ConflictChoice) -> Void
    ) {
        self.sourceURL = sourceURL
        self.targetURL = targetURL
        self.renamePreviewName = renamePreviewName
        self.onDecision = onDecision
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 38))
                .foregroundColor(.orange)

            VStack(spacing: 6) {
                Text("File Already Exists")
                    .font(.headline)

                Text("A file with this name already exists at the destination:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text(targetURL.lastPathComponent)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(6)

                Text("Auto-rename to: \(renamePreviewName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            HStack(spacing: 10) {
                Button("Cancel") {
                    onDecision(.skip)
                }
                .keyboardShortcut(.cancelAction)

                Button("Replace") {
                    onDecision(.replace)
                }

                Button("Rename") {
                    onDecision(.rename)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 380)
        .background(.ultraThinMaterial)
    }
}
