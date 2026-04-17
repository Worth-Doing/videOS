import Foundation
import Combine

@MainActor
final class BookmarkService: ObservableObject {
    @Published var bookmarks: [Bookmark] = []
    @Published var playbackStates: PlaybackStateStore = PlaybackStateStore()

    private let bookmarkURL = Defaults.appSupportURL.appendingPathComponent("bookmarks.json")
    private let stateURL = Defaults.appSupportURL.appendingPathComponent("playback-state.json")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        loadBookmarks()
        loadStates()
    }

    // MARK: - Bookmarks

    func addBookmark(mediaID: UUID, label: String, timestamp: TimeInterval) -> Bookmark {
        let bookmark = Bookmark(mediaID: mediaID, label: label, timestamp: timestamp)
        bookmarks.append(bookmark)
        saveBookmarks()
        return bookmark
    }

    func removeBookmark(id: UUID) {
        bookmarks.removeAll { $0.id == id }
        saveBookmarks()
    }

    func bookmarks(for mediaID: UUID) -> [Bookmark] {
        bookmarks.forMedia(mediaID)
    }

    func renameBookmark(id: UUID, label: String) {
        guard let index = bookmarks.firstIndex(where: { $0.id == id }) else { return }
        bookmarks[index].label = label
        saveBookmarks()
    }

    // MARK: - Resume Playback State

    func savePosition(mediaID: UUID, position: Float, timestamp: TimeInterval) {
        playbackStates.save(mediaID: mediaID, position: position, timestamp: timestamp)
        saveStates()
    }

    func resumePosition(for mediaID: UUID) -> PlaybackState? {
        let state = playbackStates.get(mediaID: mediaID)
        return state?.shouldResume == true ? state : nil
    }

    func clearPosition(mediaID: UUID) {
        playbackStates.clear(mediaID: mediaID)
        saveStates()
    }

    // MARK: - Persistence

    private func loadBookmarks() {
        guard FileManager.default.fileExists(atPath: bookmarkURL.path) else { return }
        guard let data = try? Data(contentsOf: bookmarkURL) else { return }
        bookmarks = (try? decoder.decode([Bookmark].self, from: data)) ?? []
    }

    private func saveBookmarks() {
        guard let data = try? encoder.encode(bookmarks) else { return }
        try? data.write(to: bookmarkURL, options: .atomic)
    }

    private func loadStates() {
        guard FileManager.default.fileExists(atPath: stateURL.path) else { return }
        guard let data = try? Data(contentsOf: stateURL) else { return }
        playbackStates = (try? decoder.decode(PlaybackStateStore.self, from: data)) ?? PlaybackStateStore()
    }

    private func saveStates() {
        guard let data = try? encoder.encode(playbackStates) else { return }
        try? data.write(to: stateURL, options: .atomic)
    }
}
