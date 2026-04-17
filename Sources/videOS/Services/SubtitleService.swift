import Foundation

@MainActor
final class SubtitleService: ObservableObject {
    @Published var externalSubtitles: [SubtitleTrack] = []
    @Published var subtitleDelay: Int64 = 0

    private weak var engine: PlayerEngine?

    init(engine: PlayerEngine) {
        self.engine = engine
    }

    func loadExternalSubtitle(url: URL) -> Bool {
        guard let engine else { return false }
        let success = engine.loadExternalSubtitle(path: url.path)
        if success {
            let track = SubtitleTrack(
                id: 9000 + externalSubtitles.count,
                name: url.deletingPathExtension().lastPathComponent,
                isExternal: true,
                filePath: url.path
            )
            externalSubtitles.append(track)
            engine.refreshTracks()
        }
        return success
    }

    func autoLoadSidecarSubtitles(for mediaURL: URL) {
        let sidecarFiles = FileScanner.findSidecarSubtitles(for: mediaURL)
        for file in sidecarFiles {
            _ = loadExternalSubtitle(url: file)
        }
    }

    func adjustDelay(by microseconds: Int64) {
        subtitleDelay += microseconds
        engine?.setSubtitleDelay(subtitleDelay)
    }

    func resetDelay() {
        subtitleDelay = 0
        engine?.setSubtitleDelay(0)
    }

    func selectTrack(_ trackID: Int) {
        engine?.setSubtitleTrack(trackID)
    }

    func disable() {
        engine?.setSubtitleTrack(-1)
    }
}
