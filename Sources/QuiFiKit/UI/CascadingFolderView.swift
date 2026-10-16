import SwiftUI

public struct CascadingFolderView: View {
    @ObservedObject var viewModel: CascadingFolderViewModel
    public var onDropFilesToFolder: (([URL], FolderNode) -> Void)?

    public init(viewModel: CascadingFolderViewModel, onDropFilesToFolder: (([URL], FolderNode) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDropFilesToFolder = onDropFilesToFolder
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Bar
            HStack {
                Label {
                    Text(viewModel.isCopyMode ? "Kopieren nach..." : "Verschieben nach...")
                        .font(.system(size: 13, weight: .bold))
                } icon: {
                    Image(systemName: viewModel.isCopyMode ? "plus.circle.fill" : "arrow.right.circle.fill")
                        .foregroundColor(viewModel.isCopyMode ? .green : .accentColor)
                }

                Spacer()

                if let currentTarget = viewModel.hoveredTarget {
                    Text(currentTarget.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Text(viewModel.isCopyMode ? "⌥ Kopieren" : "⌘ Verschieben")
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(viewModel.isCopyMode ? Color.green.opacity(0.2) : Color.accentColor.opacity(0.2))
                    .foregroundColor(viewModel.isCopyMode ? .green : .accentColor)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            Divider()
                .padding(.horizontal, 10)

            // Cascading Columns
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(Array(viewModel.columns.enumerated()), id: \.offset) { colIndex, folders in
                        FolderColumnView(
                            columnIndex: colIndex,
                            folders: folders,
                            selectedNode: colIndex < viewModel.selectedPath.count ? viewModel.selectedPath[colIndex] : nil,
                            hoveredNode: viewModel.hoveredTarget,
                            onHover: { node in
                                viewModel.hoverOver(node: node, atColumnIndex: colIndex)
                            },
                            onDrop: { urls, node in
                                onDropFilesToFolder?(urls, node)
                            }
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .frame(minWidth: 260, minHeight: 220)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct FolderColumnView: View {
    let columnIndex: Int
    let folders: [FolderNode]
    let selectedNode: FolderNode?
    let hoveredNode: FolderNode?
    let onHover: (FolderNode) -> Void
    let onDrop: ([URL], FolderNode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(columnTitle)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 6)
                .padding(.bottom, 2)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 3) {
                    ForEach(folders) { node in
                        FolderRowView(
                            node: node,
                            isSelected: selectedNode?.id == node.id,
                            isHovered: hoveredNode?.id == node.id,
                            onHover: {
                                onHover(node)
                            },
                            onDrop: { urls in
                                onDrop(urls, node)
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 280)
        }
        .frame(width: 170)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        )
    }

    private var columnTitle: String {
        if columnIndex == 0 {
            return "Favoriten"
        }
        return "Ebene \(columnIndex)"
    }
}

struct FolderRowView: View {
    let node: FolderNode
    let isSelected: Bool
    let isHovered: Bool
    let onHover: () -> Void
    let onDrop: ([URL]) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: node.iconName)
                .font(.system(size: 13))
                .foregroundColor(isSelected || isHovered ? .accentColor : .secondary)

            Text(node.name)
                .font(.system(size: 12, weight: isSelected || isHovered ? .semibold : .regular))
                .foregroundColor(isSelected || isHovered ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.accentColor.opacity(0.25) : (isSelected ? Color.accentColor.opacity(0.12) : Color.clear))
        )
        .contentShape(Rectangle())
        .onHover { isOver in
            if isOver {
                onHover()
            }
        }
        .dropDestination(for: URL.self) { items, _ in
            guard !items.isEmpty else { return false }
            onDrop(items)
            return true
        } isTargeted: { targeted in
            if targeted {
                onHover()
            }
        }
    }
}
