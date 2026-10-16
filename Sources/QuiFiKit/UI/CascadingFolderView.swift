import SwiftUI

public struct CascadingFolderView: View {
    @ObservedObject var viewModel: CascadingFolderViewModel
    public var onDropFilesToFolder: (([URL], FolderNode) -> Void)?

    public init(viewModel: CascadingFolderViewModel, onDropFilesToFolder: (([URL], FolderNode) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDropFilesToFolder = onDropFilesToFolder
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Sleek, minimal header
            HStack(spacing: 6) {
                Image(systemName: viewModel.isCopyMode ? "plus.circle.fill" : "arrow.right.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(viewModel.isCopyMode ? .green : .accentColor)

                Text(viewModel.isCopyMode ? "Copy to" : "Move to")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(viewModel.isCopyMode ? .green : .primary.opacity(0.85))

                Text("•")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary.opacity(0.4))

                Text(viewModel.isCopyMode ? "⌥ Copy active" : "⌥ hold to copy")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(viewModel.isCopyMode ? .green.opacity(0.8) : .secondary.opacity(0.6))

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 2)

            // Flowy, auto-expanding Miller-Columns
            HStack(alignment: .top, spacing: 10) {
                ForEach(viewModel.columns) { column in
                    FolderColumnView(
                        columnIndex: column.index,
                        columnTitle: column.title,
                        folders: column.folders,
                        selectedNode: column.index < viewModel.selectedPath.count ? viewModel.selectedPath[column.index] : nil,
                        hoveredNode: viewModel.hoveredTarget,
                        onHover: { node in
                            viewModel.hoverOver(node: node, atColumnIndex: column.index)
                        },
                        onDrop: { urls, node in
                            onDropFilesToFolder?(urls, node)
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 18)),
                        removal: .opacity
                    ))
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .animation(.spring(response: 0.32, dampingFraction: 0.88), value: viewModel.columns.map(\.id))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}

struct FolderColumnView: View {
    let columnIndex: Int
    let columnTitle: String
    let folders: [FolderNode]
    let selectedNode: FolderNode?
    let hoveredNode: FolderNode?
    let onHover: (FolderNode) -> Void
    let onDrop: ([URL], FolderNode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Column Header
            Text(columnTitle)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary.opacity(0.8))
                .lineLimit(1)
                .textCase(.uppercase)
                .padding(.horizontal, 8)
                .padding(.top, 4)

            // Scrollable list of folders
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 2) {
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
                .padding(2)
            }
            .frame(maxHeight: 280)
        }
        .frame(width: 185)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
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
                .font(.system(size: 12, weight: isSelected || isHovered ? .medium : .regular))
                .foregroundColor(isSelected || isHovered ? .primary : .primary.opacity(0.85))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.secondary.opacity(0.4))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    isHovered
                        ? Color.accentColor.opacity(0.22)
                        : (isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
                )
                .animation(.easeOut(duration: 0.16), value: isHovered)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isHovered ? Color.accentColor.opacity(0.35) : Color.clear, lineWidth: 1)
                .animation(.easeOut(duration: 0.16), value: isHovered)
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
