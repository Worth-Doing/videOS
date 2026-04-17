import Foundation
import Combine
import CLibVLC
import AppKit

protocol MediaPlayerProtocol: AnyObject {
    var isPlaying: Bool { get }
    var currentTime: Int64 { get }
    var duration: Int64 { get }
    var position: Float { get }
    var volume: Int { get set }
    var rate: Float { get set }

    func open(url: URL)
    func play()
    func pause()
    func stop()
    func togglePause()
    func seek(to position: Float)
    func seekTime(to ms: Int64)
    func seekRelative(seconds: Double)
    func setVideoView(_ view: NSView)
}

final class PlayerEngine: MediaPlayerProtocol, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: Int64 = 0
    @Published var duration: Int64 = 0
    @Published var position: Float = 0
    @Published var volume: Int = 100 {
        didSet { applyVolume() }
    }
    @Published var rate: Float = 1.0 {
        didSet { applyRate() }
    }
    @Published var isMuted = false
    @Published var isSeekable = false
    @Published var state: VLCPlayerState = .idle
    @Published var audioTracks: [AudioTrack] = []
    @Published var subtitleTracks: [SubtitleTrack] = []
    @Published var currentAudioTrack: Int = -1
    @Published var currentSubtitleTrack: Int = -1
    @Published var bufferingProgress: Float = 0
    @Published var isInitialized = false

    private var vlcInstance: OpaquePointer?
    private var mediaPlayer: OpaquePointer?
    private var currentMedia: OpaquePointer?
    private var videoView: NSView?
    private var callbackPointer: UnsafeMutableRawPointer?

    enum VLCPlayerState: Equatable {
        case idle
        case opening
        case buffering(Float)
        case playing
        case paused
        case stopped
        case ended
        case error
    }

    init() {
        initVLC()
    }

    deinit {
        detachEvents()
        if let mp = mediaPlayer { libvlc_media_player_release(mp) }
        if let media = currentMedia { libvlc_media_release(media) }
        if let instance = vlcInstance { libvlc_release(instance) }
    }

    private func initVLC() {
        var args: [String] = [
            "--no-video-title-show",
            "--no-stats",
            "--no-snapshot-preview",
            "--no-osd",
            "--no-lua",
        ]

        // Resolve plugin path: app bundle → VLC.app fallback
        let bundlePlugins = Bundle.main.resourceURL?.appendingPathComponent("plugins").path
        let vlcAppPlugins = "/Applications/VLC.app/Contents/MacOS/plugins"

        if let bp = bundlePlugins, FileManager.default.fileExists(atPath: bp) {
            args.append("--plugin-path=\(bp)")
        } else if FileManager.default.fileExists(atPath: vlcAppPlugins) {
            args.append("--plugin-path=\(vlcAppPlugins)")
        }

        let cArgs = args.map { strdup($0) }
        defer { cArgs.forEach { free($0) } }

        var argv: [UnsafePointer<CChar>?] = cArgs.map { UnsafePointer($0) }
        vlcInstance = libvlc_new(Int32(args.count), &argv)

        guard vlcInstance != nil else {
            print("[videOS] ERROR: Failed to initialize libVLC — plugins not found?")
            return
        }

        mediaPlayer = libvlc_media_player_new(vlcInstance)
        guard mediaPlayer != nil else {
            print("[videOS] ERROR: Failed to create VLC media player")
            return
        }

        attachEvents()
        applyVolume()
        isInitialized = true
    }

    func setVideoView(_ view: NSView) {
        videoView = view
        libvlc_media_player_set_nsobject(mediaPlayer, Unmanaged.passUnretained(view).toOpaque())
    }

    func open(url: URL) {
        guard isInitialized else { return }
        stop()

        if let media = currentMedia {
            libvlc_media_release(media)
        }

        if url.isFileURL {
            currentMedia = libvlc_media_new_path(vlcInstance, url.path)
        } else {
            currentMedia = libvlc_media_new_location(vlcInstance, url.absoluteString)
        }

        guard currentMedia != nil else { return }

        libvlc_media_player_set_media(mediaPlayer, currentMedia)
        play()
    }

    func play() {
        guard isInitialized else { return }
        libvlc_media_player_play(mediaPlayer)
    }

    func pause() {
        guard isInitialized else { return }
        libvlc_media_player_pause(mediaPlayer)
    }

    func stop() {
        guard isInitialized else { return }
        libvlc_media_player_stop(mediaPlayer)
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            self?.position = 0
            self?.currentTime = 0
            self?.state = .stopped
        }
    }

    func togglePause() {
        guard isInitialized else { return }
        if isPlaying { pause() } else { play() }
    }

    func seek(to pos: Float) {
        guard isInitialized else { return }
        let clamped = max(0, min(1, pos))
        libvlc_media_player_set_position(mediaPlayer, clamped)
    }

    func seekTime(to ms: Int64) {
        guard isInitialized else { return }
        libvlc_media_player_set_time(mediaPlayer, ms)
    }

    func seekRelative(seconds: Double) {
        guard isInitialized else { return }
        let current = libvlc_media_player_get_time(mediaPlayer)
        let target = current + Int64(seconds * 1000)
        let clamped = max(0, min(target, duration))
        libvlc_media_player_set_time(mediaPlayer, clamped)
    }

    func extractMetadata(for url: URL) -> MediaMetadata {
        MetadataService.extract(from: url, vlcInstance: vlcInstance)
    }

    func setAudioTrack(_ trackID: Int) {
        libvlc_audio_set_track(mediaPlayer, Int32(trackID))
        currentAudioTrack = trackID
    }

    func setSubtitleTrack(_ trackID: Int) {
        libvlc_video_set_spu(mediaPlayer, Int32(trackID))
        currentSubtitleTrack = trackID
    }

    func loadExternalSubtitle(path: String) -> Bool {
        libvlc_video_set_subtitle_file(mediaPlayer, path) == 1
    }

    func setSubtitleDelay(_ microseconds: Int64) {
        libvlc_video_set_spu_delay(mediaPlayer, microseconds)
    }

    func setAudioDelay(_ microseconds: Int64) {
        libvlc_audio_set_delay(mediaPlayer, microseconds)
    }

    func toggleMute() {
        isMuted.toggle()
        libvlc_audio_set_mute(mediaPlayer, isMuted ? 1 : 0)
    }

    func snapshot(path: String, width: UInt32 = 0, height: UInt32 = 0) -> Bool {
        libvlc_video_take_snapshot(mediaPlayer, 0, path, width, height) == 0
    }

    private func applyVolume() {
        libvlc_audio_set_volume(mediaPlayer, Int32(volume))
    }

    private func applyRate() {
        libvlc_media_player_set_rate(mediaPlayer, rate)
    }

    func refreshTracks() {
        refreshAudioTracks()
        refreshSubtitleTracks()
    }

    private func refreshAudioTracks() {
        guard let desc = libvlc_audio_get_track_description(mediaPlayer) else { return }
        var tracks: [AudioTrack] = []
        var current = desc
        while true {
            let name = current.pointee.psz_name.map { String(cString: $0) } ?? "Track \(current.pointee.i_id)"
            tracks.append(AudioTrack(id: Int(current.pointee.i_id), name: name))
            guard let next = current.pointee.p_next else { break }
            current = next
        }
        libvlc_track_description_list_release(desc)
        DispatchQueue.main.async { [weak self] in
            self?.audioTracks = tracks
            self?.currentAudioTrack = Int(libvlc_audio_get_track(self?.mediaPlayer))
        }
    }

    private func refreshSubtitleTracks() {
        guard let desc = libvlc_video_get_spu_description(mediaPlayer) else { return }
        var tracks: [SubtitleTrack] = []
        var current = desc
        while true {
            let name = current.pointee.psz_name.map { String(cString: $0) } ?? "Track \(current.pointee.i_id)"
            tracks.append(SubtitleTrack(id: Int(current.pointee.i_id), name: name))
            guard let next = current.pointee.p_next else { break }
            current = next
        }
        libvlc_track_description_list_release(desc)
        DispatchQueue.main.async { [weak self] in
            self?.subtitleTracks = tracks
            self?.currentSubtitleTrack = Int(libvlc_video_get_spu(self?.mediaPlayer))
        }
    }

    // MARK: - VLC Event Handling

    private func attachEvents() {
        guard let mp = mediaPlayer else { return }
        let manager = libvlc_media_player_event_manager(mp)

        let pointer = Unmanaged.passUnretained(self).toOpaque()
        callbackPointer = pointer

        let events: [Int32] = [
            Int32(libvlc_MediaPlayerPlaying),
            Int32(libvlc_MediaPlayerPaused),
            Int32(libvlc_MediaPlayerStopped),
            Int32(libvlc_MediaPlayerEndReached),
            Int32(libvlc_MediaPlayerEncounteredError),
            Int32(libvlc_MediaPlayerTimeChanged),
            Int32(libvlc_MediaPlayerPositionChanged),
            Int32(libvlc_MediaPlayerLengthChanged),
            Int32(libvlc_MediaPlayerBuffering),
            Int32(libvlc_MediaPlayerSeekableChanged),
            Int32(libvlc_MediaPlayerOpening),
        ]

        for event in events {
            libvlc_event_attach(manager, event, vlcEventCallback, pointer)
        }
    }

    private func detachEvents() {
        guard let mp = mediaPlayer, let pointer = callbackPointer else { return }
        let manager = libvlc_media_player_event_manager(mp)

        let events: [Int32] = [
            Int32(libvlc_MediaPlayerPlaying),
            Int32(libvlc_MediaPlayerPaused),
            Int32(libvlc_MediaPlayerStopped),
            Int32(libvlc_MediaPlayerEndReached),
            Int32(libvlc_MediaPlayerEncounteredError),
            Int32(libvlc_MediaPlayerTimeChanged),
            Int32(libvlc_MediaPlayerPositionChanged),
            Int32(libvlc_MediaPlayerLengthChanged),
            Int32(libvlc_MediaPlayerBuffering),
            Int32(libvlc_MediaPlayerSeekableChanged),
            Int32(libvlc_MediaPlayerOpening),
        ]

        for event in events {
            libvlc_event_detach(manager, event, vlcEventCallback, pointer)
        }
    }

    fileprivate func handleEvent(_ event: UnsafePointer<libvlc_event_t>) {
        let type = event.pointee.type

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            switch Int(type) {
            case libvlc_MediaPlayerPlaying:
                self.isPlaying = true
                self.state = .playing
                self.refreshTracks()

            case libvlc_MediaPlayerPaused:
                self.isPlaying = false
                self.state = .paused

            case libvlc_MediaPlayerStopped:
                self.isPlaying = false
                self.state = .stopped

            case libvlc_MediaPlayerEndReached:
                self.isPlaying = false
                self.state = .ended

            case libvlc_MediaPlayerEncounteredError:
                self.isPlaying = false
                self.state = .error

            case libvlc_MediaPlayerTimeChanged:
                self.currentTime = event.pointee.u.media_player_time_changed.new_time

            case libvlc_MediaPlayerPositionChanged:
                self.position = event.pointee.u.media_player_position_changed.new_position

            case libvlc_MediaPlayerLengthChanged:
                self.duration = event.pointee.u.media_player_length_changed.new_length

            case libvlc_MediaPlayerBuffering:
                let cache = event.pointee.u.media_player_buffering.new_cache
                self.bufferingProgress = cache
                self.state = cache < 100 ? .buffering(cache) : .playing

            case libvlc_MediaPlayerSeekableChanged:
                self.isSeekable = event.pointee.u.media_player_seekable_changed.new_seekable != 0

            case libvlc_MediaPlayerOpening:
                self.state = .opening

            default:
                break
            }
        }
    }
}

private func vlcEventCallback(event: UnsafePointer<libvlc_event_t>?, data: UnsafeMutableRawPointer?) {
    guard let event, let data else { return }
    let engine = Unmanaged<PlayerEngine>.fromOpaque(data).takeUnretainedValue()
    engine.handleEvent(event)
}
