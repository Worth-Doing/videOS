import SwiftUI
import AppKit

struct LibraryView: View {
    @ObservedObject var viewModel: LibraryViewModel
    var onSelect: (MediaItem) -> Void

    @State private var hoveredItemID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            if viewModel.filteredItems.isEmpty {
                emptyState
            } else {
                switch viewModel.viewMode {
                case .list:
                    listView
                case .grid:
                    gridView
                }
            }

            // Status bar
            StatusBar(
                itemCount: viewModel.filteredItems.count,
                additionalInfo: totalDurationString
            )
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                TextField("Search library...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Sort picker with label
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Picker("", selection: $viewModel.sortOrder) {
                    ForEach(LibraryViewModel.SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .labelsHidden()
            }
            .frame(width: 140)

            // View mode segmented control
            Picker("", selection: $viewModel.viewMode) {
                Image(systemName: "list.bullet").tag(LibraryViewModel.ViewMode.list)
                Image(systemName: "square.grid.2x2").tag(LibraryViewModel.ViewMode.grid)
            }
            .pickerStyle(.segmented)
            .frame(width: 80)
            .labelsHidden()

            // Add button
            Button {
                viewModel.addFolder()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Add folder to library")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassToolbar()
    }

    // MARK: - List View

    private var listView: some View {
        List(viewModel.filteredItems, selection: $viewModel.selectedItemIDs) { item in
            MediaItemRow(
                item: item,
                isHovered: hoveredItemID == item.id,
                showFileSize: true
            )
            .onTapGesture(count: 2) {
                onSelect(item)
            }
            .onHover { hovering in
                hoveredItemID = hovering ? item.id : nil
            }
            .contextMenu {
                itemContextMenu(item)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    // MARK: - Grid View

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 170, maximum: 220), spacing: 14)
            ], spacing: 14) {
                ForEach(viewModel.filteredItems) { item in
                    MediaItemCard(
                        item: item,
                        isHovered: hoveredItemID == item.id
                    )
                    .onTapGesture(count: 2) {
                        onSelect(item)
                    }
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredItemID = hovering ? item.id : nil
                        }
                    }
                    .contextMenu {
                        itemContextMenu(item)
                    }
                }
            }
            .padding(14)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.quaternary)
                    .frame(width: 80, height: 80)
                Image(systemName: "film.stack")
                    .font(.system(size: 36, weight: .ultraLight))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                Text("No media in library")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.primary)
                Text("Scan a folder to add media files")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Button {
                viewModel.addFolder()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 13))
                    Text("Add Folder")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("Drag and drop files or folders here")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func itemContextMenu(_ item: MediaItem) -> some View {
        Button("Play") { onSelect(item) }
        Divider()
        Button("Show in Finder") {
            NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: item.url.deletingLastPathComponent().path)
        }
        Button("Copy Path") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.url.path, forType: .string)
        }
        Divider()
        Button("Remove from Library", role: .destructive) {
            viewModel.libraryManager.remove(item: item)
        }
    }

    // MARK: - Helpers

    private var totalDurationString: String? {
        let totalDuration = viewModel.filteredItems.compactMap(\.duration).reduce(0, +)
        guard totalDuration > 0 else { return nil }
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m total"
        }
        return "\(minutes)m total"
    }
}

// MARK: - Media Item Row

struct MediaItemRow: View {
    let item: MediaItem
    var isHovered: Bool = false
    var showFileSize: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: item.mediaType == .video ? "film" : "music.note")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(iconColor.opacity(0.8))
            }

            // Main info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(item.fileExtension.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 3))

                    if let duration = item.duration {
                        Text(TimeFormatter.format(seconds: duration))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    if let res = item.resolution {
                        Text(res.displayString)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    if showFileSize, let size = item.fileSize {
                        Text(formatSize(size))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            // Play count indicator
            if item.playCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.green.opacity(0.7))
                    if item.playCount > 1 {
                        Text("\(item.playCount)")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }

    private var iconColor: Color {
        item.mediaType == .video ? .blue : .purple
    }

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Media Item Card

struct MediaItemCard: View {
    let item: MediaItem
    var isHovered: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail area
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.12),
                                Color.gray.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(16/9, contentMode: .fit)

                Image(systemName: item.mediaType == .video ? "film" : "music.note")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary.opacity(0.5))

                // Play overlay on hover
                if isHovered {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.black.opacity(0.3))
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 4)
                    }
                    .transition(.opacity)
                }

                // Duration badge
                if let duration = item.duration {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(TimeFormatter.format(seconds: duration))
                                .font(.system(size: 10, weight: .semibold).monospacedDigit())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.black.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(6)
                        }
                    }
                }
            }

            // Info area
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text(item.fileExtension.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)

                    if let res = item.resolution {
                        Text(res.displayString)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.white.opacity(isHovered ? 0.15 : 0.05), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(isHovered ? 0.2 : 0.1), radius: isHovered ? 8 : 4, y: isHovered ? 4 : 2)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}
