import Foundation
import Combine

@MainActor
final class PlaylistViewModel: ObservableObject {
    @Published var selectedPlaylist: Playlist?
    @Published var newPlaylistName = ""
    @Published var isCreating = false

    let playlistManager: PlaylistManager
    let libraryManager: LibraryManager

    init(playlistManager: PlaylistManager, libraryManager: LibraryManager) {
        self.playlistManager = playlistManager
        self.libraryManager = libraryManager
    }

    func createPlaylist() {
        let name = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let playlist = playlistManager.create(name: name)
        selectedPlaylist = playlist
        newPlaylistName = ""
        isCreating = false
    }

    func deletePlaylist(id: UUID) {
        if selectedPlaylist?.id == id {
            selectedPlaylist = nil
        }
        playlistManager.delete(id: id)
    }

    func items(for playlist: Playlist) -> [MediaItem] {
        playlist.itemIDs.compactMap { libraryManager.item(for: $0) }
    }

    func addToPlaylist(_ itemID: UUID) {
        guard let playlist = selectedPlaylist else { return }
        playlistManager.addItem(itemID, to: playlist.id)
        selectedPlaylist = playlistManager.playlist(for: playlist.id)
    }

    func removeFromPlaylist(_ itemID: UUID) {
        guard let playlist = selectedPlaylist else { return }
        playlistManager.removeItem(itemID, from: playlist.id)
        selectedPlaylist = playlistManager.playlist(for: playlist.id)
    }
}
