import SwiftUI

struct PlaylistView: View {
    @ObservedObject var viewModel: PlaylistViewModel
    var onSelect: (MediaItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let playlist = viewModel.selectedPlaylist {
                playlistDetail(playlist)
            } else {
                playlistList
            }
        }
    }

    // MARK: - Playlist List

    private var playlistList: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Playlists")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()

                Text("\(viewModel.playlistManager.playlists.count) playlists")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Button {
                    viewModel.isCreating = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Create new playlist")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassToolbar()

            if viewModel.playlistManager.playlists.isEmpty {
                playlistEmptyState
            } else {
                List(viewModel.playlistManager.playlists) { playlist in
                    PlaylistRowView(
                        playlist: playlist,
                        itemCount: playlist.count,
                        onRename: { newName in
                            viewModel.playlistManager.rename(id: playlist.id, to: newName)
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedPlaylist = playlist
                    }
                    .contextMenu {
                        Button("Open") {
                            viewModel.selectedPlaylist = playlist
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            viewModel.deletePlaylist(id: playlist.id)
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .sheet(isPresented: $viewModel.isCreating) {
            createPlaylistSheet
        }
    }

    // MARK: - Playlist Row

    // MARK: - Empty State

    private var playlistEmptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.quaternary)
                    .frame(width: 72, height: 72)
                Image(systemName: "music.note.list")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                Text("No playlists yet")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                Text("Create a playlist to organize your media")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Button {
                viewModel.isCreating = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 13))
                    Text("Create Playlist")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 7)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Playlist Detail

    private func playlistDetail(_ playlist: Playlist) -> some View {
        VStack(spacing: 0) {
            // Detail header
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    // Back button
                    Button {
                        viewModel.selectedPlaylist = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 13))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    // Playlist icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        Image(systemName: "music.note.list")
                            .font(.system(size: 16))
                            .foregroundStyle(.purple)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(playlist.name)
                            .font(.system(size: 15, weight: .semibold))
                        Text("\(playlist.count) items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Play All button
                    if !playlist.isEmpty {
                        Button {
                            let items = viewModel.items(for: playlist)
                            if let first = items.first {
                                onSelect(first)
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10))
                                Text("Play All")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .glassToolbar()

            // Items
            let items = viewModel.items(for: playlist)
            if items.isEmpty {
                playlistDetailEmptyState
            } else {
                List {
                    ForEach(items) { item in
                        MediaItemRow(item: item)
                            .onTapGesture(count: 2) {
                                onSelect(item)
                            }
                            .contextMenu {
                                Button("Play") { onSelect(item) }
                                Divider()
                                Button("Remove from Playlist", role: .destructive) {
                                    viewModel.removeFromPlaylist(item.id)
                                }
                            }
                    }
                    .onMove { source, destination in
                        viewModel.playlistManager.moveItems(
                            in: playlist.id,
                            from: source,
                            to: destination
                        )
                        viewModel.selectedPlaylist = viewModel.playlistManager.playlist(for: playlist.id)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            // Status bar
            StatusBar(
                itemCount: items.count,
                additionalInfo: nil
            )
        }
    }

    private var playlistDetailEmptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text("Playlist is empty")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Drag items here or add from the library")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Create Sheet

    private var createPlaylistSheet: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 28))
                .foregroundStyle(.purple)

            Text("New Playlist")
                .font(.headline)

            TextField("Playlist name", text: $viewModel.newPlaylistName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 260)
                .onSubmit {
                    viewModel.createPlaylist()
                }

            HStack(spacing: 12) {
                Button("Cancel") {
                    viewModel.isCreating = false
                    viewModel.newPlaylistName = ""
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    viewModel.createPlaylist()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(28)
    }
}

// MARK: - Playlist Row View

struct PlaylistRowView: View {
    let playlist: Playlist
    let itemCount: Int
    var onRename: (String) -> Void

    @State private var isEditing = false
    @State private var editName: String = ""

    var body: some View {
        HStack(spacing: 10) {
            // Playlist artwork/icon
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.25), .blue.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                Image(systemName: "music.note.list")
                    .font(.system(size: 14))
                    .foregroundStyle(.purple.opacity(0.8))
            }

            // Name (editable on double-click)
            VStack(alignment: .leading, spacing: 2) {
                if isEditing {
                    TextField("Name", text: $editName, onCommit: {
                        let trimmed = editName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onRename(trimmed)
                        }
                        isEditing = false
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                } else {
                    Text(playlist.name)
                        .font(.system(size: 13, weight: .medium))
                        .onTapGesture(count: 2) {
                            editName = playlist.name
                            isEditing = true
                        }
                }

                Text("\(itemCount) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
