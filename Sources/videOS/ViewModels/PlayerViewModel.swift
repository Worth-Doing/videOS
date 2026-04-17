import Foundation
import Combine
import SwiftUI

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var currentItem: MediaItem?
    @Published var isFullscreen = false
    @Published var showControls = true
    @Published var showSidebar = true
    @Published var playbackSpeed: Float = 1.0
    @Published var currentMediaInfo: MediaInfo?
    @Published var currentPlaylistID: UUID?
    @Published var playlistIndex: Int = 0
    @Published var errorMessage: String?

    let engine: PlayerEngine
    let bookmarkService: BookmarkService
    let subtitleService: SubtitleService
    let libraryManager: LibraryManager
    var playlistManager: PlaylistManager?

    private var hideControlsTask: Task<Void, Never>?
    private var positionSaveTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(engine: PlayerEngine, bookmarkService: BookmarkService, libraryManager: LibraryManager) {
        self.engine = engine
        self.bookmarkService = bookmarkService
        self.subtitleService = SubtitleService(engine: engine)
        self.libraryManager = libraryManager

        setupAutoSave()
    }

    func open(item: MediaItem) {
        saveCurrentPosition()

        currentItem = item
        currentMediaInfo = nil
        errorMessage = nil
        engine.open(url: item.url)
        libraryManager.markPlayed(item.id)

        if item.isLocal {
            subtitleService.autoLoadSidecarSubtitles(for: item.url)
        }

        let shouldResume = Defaults.bool(for: .resumePlayback, default: true)
        if shouldResume, let state = bookmarkService.resumePosition(for: item.id) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.engine.seek(to: state.position)
            }
        }

        // Extract metadata on background thread
        Task.detached { [weak self] in
            guard let self else { return }
            let meta = self.engine.extractMetadata(for: item.url)
            let fileSize = MetadataService.fileSizeString(for: item.url)
            await MainActor.run {
                self.currentMediaInfo = MediaInfo(
                    title: meta.title,
                    artist: meta.artist,
                    album: meta.album,
                    genre: meta.genre,
                    date: meta.date,
                    duration: meta.duration,
                    fileSize: fileSize,
                    codec: meta.codec,
                    resolution: meta.resolution,
                    artworkURL: meta.artworkURL
                )
            }
        }

        resetControlsTimer()
    }

    func openURL(_ url: URL) {
        let item = MediaItem(url: url)
        libraryManager.add(url: url)
        open(item: item)
    }

    func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .audio, .mpeg4Movie, .quickTimeMovie, .avi]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true

        guard panel.runModal() == .OK else { return }

        let urls = panel.urls
        if urls.count == 1, let url = urls.first {
            if url.hasDirectoryPath {
                libraryManager.scan(directories: [url])
            } else {
                openURL(url)
            }
        } else {
            libraryManager.add(urls: urls.filter { !$0.hasDirectoryPath })
            if let first = urls.first(where: { !$0.hasDirectoryPath }) {
                openURL(first)
            }
        }
    }

    func togglePlay() {
        engine.togglePause()
        resetControlsTimer()
    }

    func seek(to position: Float) {
        engine.seek(to: position)
        resetControlsTimer()
    }

    func seekRelative(seconds: Double) {
        engine.seekRelative(seconds: seconds)
        resetControlsTimer()
    }

    func setVolume(_ volume: Int) {
        engine.volume = max(0, min(AppConstants.maxVolume, volume))
    }

    func adjustVolume(by delta: Int) {
        setVolume(engine.volume + delta)
    }

    func toggleMute() {
        engine.toggleMute()
    }

    func setSpeed(_ speed: Float) {
        playbackSpeed = speed
        engine.rate = speed
    }

    func cycleSpeedUp() {
        let steps = KeyboardShortcuts.speedSteps
        if let idx = steps.firstIndex(where: { $0 > playbackSpeed }) {
            setSpeed(steps[idx])
        }
    }

    func cycleSpeedDown() {
        let steps = KeyboardShortcuts.speedSteps
        if let idx = steps.lastIndex(where: { $0 < playbackSpeed }) {
            setSpeed(steps[idx])
        }
    }

    func resetSpeed() {
        setSpeed(1.0)
    }

    func toggleFullscreen() {
        isFullscreen.toggle()
        if let window = NSApp.keyWindow {
            window.toggleFullScreen(nil)
        }
    }

    func addBookmark(label: String) {
        guard let item = currentItem else { return }
        let timestamp = TimeInterval(engine.currentTime) / 1000.0
        _ = bookmarkService.addBookmark(mediaID: item.id, label: label, timestamp: timestamp)
    }

    func jumpToBookmark(_ bookmark: Bookmark) {
        engine.seekTime(to: Int64(bookmark.timestamp * 1000))
        resetControlsTimer()
    }

    func snapshot() {
        let path = NSTemporaryDirectory() + "videOS_snapshot_\(Int(Date().timeIntervalSince1970)).png"
        _ = engine.snapshot(path: path)
    }

    func handleKeyAction(_ action: KeyboardAction) {
        switch action {
        case .togglePlay: togglePlay()
        case .seekForward: seekRelative(seconds: KeyboardShortcuts.seekInterval)
        case .seekForwardLarge: seekRelative(seconds: KeyboardShortcuts.seekIntervalLarge)
        case .seekForwardSmall: seekRelative(seconds: KeyboardShortcuts.seekIntervalSmall)
        case .seekBackward: seekRelative(seconds: -KeyboardShortcuts.seekInterval)
        case .seekBackwardLarge: seekRelative(seconds: -KeyboardShortcuts.seekIntervalLarge)
        case .seekBackwardSmall: seekRelative(seconds: -KeyboardShortcuts.seekIntervalSmall)
        case .volumeUp: adjustVolume(by: KeyboardShortcuts.volumeStep)
        case .volumeDown: adjustVolume(by: -KeyboardShortcuts.volumeStep)
        case .toggleMute: toggleMute()
        case .toggleFullscreen: toggleFullscreen()
        case .speedUp: cycleSpeedUp()
        case .speedDown: cycleSpeedDown()
        case .speedReset: resetSpeed()
        case .nextTrack: playNext()
        case .previousTrack: playPrevious()
        case .snapshot: snapshot()
        }
    }

    // MARK: - Controls Auto-Hide

    func resetControlsTimer() {
        showControls = true
        hideControlsTask?.cancel()

        guard engine.isPlaying else { return }

        let delaySec = Defaults.double(for: .controlBarAutoHideDelay, default: 3.0)
        let delayNs = UInt64(delaySec * 1_000_000_000)

        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: delayNs)
            guard !Task.isCancelled else { return }
            showControls = false
        }
    }

    func onMouseMove() {
        resetControlsTimer()
    }

    // MARK: - Auto-save Position

    private func setupAutoSave() {
        engine.$position
            .throttle(for: .seconds(AppConstants.positionSaveInterval), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                self?.saveCurrentPosition()
            }
            .store(in: &cancellables)

        engine.$state
            .filter { $0 == .ended }
            .sink { [weak self] _ in
                guard let self, let item = self.currentItem else { return }
                self.bookmarkService.clearPosition(mediaID: item.id)
                self.playNext()
            }
            .store(in: &cancellables)

        engine.$state
            .filter { $0 == .error }
            .sink { [weak self] _ in
                self?.errorMessage = "Playback failed. The file may be corrupted or the format is not supported."
            }
            .store(in: &cancellables)
    }

    private func saveCurrentPosition() {
        guard let item = currentItem else { return }
        let pos = engine.position
        let time = TimeInterval(engine.currentTime) / 1000.0
        guard pos > 0 else { return }
        bookmarkService.savePosition(mediaID: item.id, position: pos, timestamp: time)
    }

    // MARK: - Playlist Navigation

    func playNext() {
        guard let playlistID = currentPlaylistID,
              let playlist = playlistManager?.playlist(for: playlistID) else { return }
        let nextIndex = playlistIndex + 1
        guard nextIndex < playlist.itemIDs.count else { return }
        let itemID = playlist.itemIDs[nextIndex]
        guard let item = libraryManager.item(for: itemID) else { return }
        playlistIndex = nextIndex
        open(item: item)
    }

    func playPrevious() {
        guard let playlistID = currentPlaylistID,
              let playlist = playlistManager?.playlist(for: playlistID) else { return }
        let prevIndex = playlistIndex - 1
        guard prevIndex >= 0 else { return }
        let itemID = playlist.itemIDs[prevIndex]
        guard let item = libraryManager.item(for: itemID) else { return }
        playlistIndex = prevIndex
        open(item: item)
    }

    // MARK: - Error Handling

    func dismissError() {
        errorMessage = nil
    }
}
