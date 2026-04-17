import Foundation
import Combine

@MainActor
final class PlaylistManager: ObservableObject {
    @Published var playlists: [Playlist] = []

    private let storageURL = Defaults.appSupportURL.appendingPathComponent("playlists.json")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    func create(name: String) -> Playlist {
        let playlist = Playlist(name: name)
        playlists.append(playlist)
        save()
        return playlist
    }

    func delete(id: UUID) {
        playlists.removeAll { $0.id == id }
        save()
    }

    func rename(id: UUID, to name: String) {
        guard let index = index(of: id) else { return }
        playlists[index].name = name
        save()
    }

    func addItem(_ itemID: UUID, to playlistID: UUID) {
        guard let index = index(of: playlistID) else { return }
        playlists[index].add(itemID)
        save()
    }

    func removeItem(_ itemID: UUID, from playlistID: UUID) {
        guard let index = index(of: playlistID) else { return }
        playlists[index].remove(itemID)
        save()
    }

    func moveItems(in playlistID: UUID, from source: IndexSet, to destination: Int) {
        guard let index = index(of: playlistID) else { return }
        playlists[index].move(from: source, to: destination)
        save()
    }

    func playlist(for id: UUID) -> Playlist? {
        playlists.first { $0.id == id }
    }

    private func index(of id: UUID) -> Int? {
        playlists.firstIndex { $0.id == id }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        guard let data = try? Data(contentsOf: storageURL) else { return }
        playlists = (try? decoder.decode([Playlist].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? encoder.encode(playlists) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}
