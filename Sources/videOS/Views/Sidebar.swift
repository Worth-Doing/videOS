import SwiftUI

enum SidebarSection: String, CaseIterable {
    case library = "Library"
    case playlists = "Playlists"
    case streams = "Streams"
    case bookmarks = "Bookmarks"

    var icon: String {
        switch self {
        case .library: return "folder.fill"
        case .playlists: return "music.note.list"
        case .streams: return "globe"
        case .bookmarks: return "bookmark.fill"
        }
    }
}

struct Sidebar: View {
    @Binding var selectedSection: SidebarSection
    @ObservedObject var playlistManager: PlaylistManager
    @ObservedObject var streamService: StreamService
    @ObservedObject var libraryManager: LibraryManager

    @State private var hoveredSection: SidebarSection?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader

            List(selection: Binding(
                get: { selectedSection },
                set: { if let s = $0 { selectedSection = s } }
            )) {
                // Recently Played section
                if !recentItems.isEmpty {
                    Section {
                        ForEach(recentItems.prefix(3), id: \.id) { item in
                            HStack(spacing: 8) {
                                Image(systemName: item.mediaType == .video ? "film" : "music.note")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 16)
                                Text(item.title)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 1)
                        }
                    } header: {
                        Text("Recently Played")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }
                }

                // Main navigation
                Section {
                    ForEach(SidebarSection.allCases, id: \.self) { section in
                        sidebarNavigationItem(section)
                            .tag(section)
                    }
                } header: {
                    Text("Navigation")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }

                // Playlists section
                Section {
                    ForEach(playlistManager.playlists) { playlist in
                        HStack(spacing: 8) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 11))
                                .foregroundStyle(.purple)
                                .frame(width: 18)
                            Text(playlist.name)
                                .font(.system(size: 13))
                                .lineLimit(1)
                            Spacer()
                            Text("\(playlist.count)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(.quaternary)
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 1)
                    }

                    Button {
                        _ = playlistManager.create(name: "New Playlist")
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Text("New Playlist")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Playlists")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 180, idealWidth: 220, maxWidth: 280)
        .glassBackground(material: .sidebar)
    }

    // MARK: - Sidebar Header

    private var sidebarHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 18))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("videOS")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassToolbar()
    }

    // MARK: - Navigation Items

    private func sidebarNavigationItem(_ section: SidebarSection) -> some View {
        HStack(spacing: 8) {
            Image(systemName: section.icon)
                .font(.system(size: 13))
                .foregroundStyle(selectedSection == section ? .white : .secondary)
                .frame(width: 20)
            Text(section.rawValue)
                .font(.system(size: 13))
            Spacer()

            if let badge = badgeCount(for: section), badge > 0 {
                Text("\(badge)")
                    .font(.caption2.monospacedDigit().bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(badgeColor(for: section))
                    )
            }
        }
        .padding(.vertical, 2)
        .contentShape(RoundedRectangle(cornerRadius: 6))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredSection = hovering ? section : nil
            }
        }
    }

    // MARK: - Helpers

    private func badgeCount(for section: SidebarSection) -> Int? {
        switch section {
        case .library:
            return libraryManager.items.count
        case .streams:
            return streamService.recentStreams.isEmpty ? nil : streamService.recentStreams.count
        case .playlists:
            return playlistManager.playlists.isEmpty ? nil : playlistManager.playlists.count
        case .bookmarks:
            return nil
        }
    }

    private func badgeColor(for section: SidebarSection) -> Color {
        switch section {
        case .library: return .blue.opacity(0.7)
        case .streams: return .green.opacity(0.7)
        case .playlists: return .purple.opacity(0.7)
        case .bookmarks: return .orange.opacity(0.7)
        }
    }

    private var recentItems: [MediaItem] {
        libraryManager.items
            .filter { $0.lastPlayedDate != nil }
            .sorted { ($0.lastPlayedDate ?? .distantPast) > ($1.lastPlayedDate ?? .distantPast) }
    }
}
