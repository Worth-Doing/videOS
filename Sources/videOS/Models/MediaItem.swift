import Foundation

struct MediaItem: Codable, Identifiable, Hashable {
    let id: UUID
    var url: URL
    var title: String
    var duration: TimeInterval?
    var fileSize: Int64?
    var codec: String?
    var resolution: MediaResolution?
    var addedDate: Date
    var lastPlayedDate: Date?
    var playCount: Int

    init(url: URL, title: String? = nil) {
        self.id = UUID()
        self.url = url
        self.title = title ?? url.deletingPathExtension().lastPathComponent
        self.addedDate = Date()
        self.playCount = 0
    }

    var isLocal: Bool {
        url.isFileURL
    }

    var isStream: Bool {
        !url.isFileURL
    }

    var fileExtension: String {
        url.pathExtension.lowercased()
    }

    static let videoExtensions: Set<String> = [
        "mp4", "mkv", "avi", "mov", "wmv", "flv", "webm", "m4v",
        "mpg", "mpeg", "3gp", "ogv", "ts", "vob", "divx", "asf"
    ]

    static let audioExtensions: Set<String> = [
        "mp3", "flac", "aac", "ogg", "wma", "wav", "m4a", "opus",
        "aiff", "ape", "alac"
    ]

    static let subtitleExtensions: Set<String> = [
        "srt", "ass", "ssa", "sub", "idx", "vtt"
    ]

    var mediaType: MediaType {
        if Self.videoExtensions.contains(fileExtension) { return .video }
        if Self.audioExtensions.contains(fileExtension) { return .audio }
        if isStream { return .stream }
        return .unknown
    }
}

struct MediaResolution: Codable, Hashable {
    let width: Int
    let height: Int

    var displayString: String {
        if height >= 2160 { return "4K" }
        if height >= 1440 { return "1440p" }
        if height >= 1080 { return "1080p" }
        if height >= 720 { return "720p" }
        if height >= 480 { return "480p" }
        return "\(width)x\(height)"
    }
}

enum MediaType: String, Codable {
    case video
    case audio
    case stream
    case unknown
}
