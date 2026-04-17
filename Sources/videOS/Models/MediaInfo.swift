import Foundation

struct MediaInfo: Identifiable {
    let id = UUID()
    let title: String?
    let artist: String?
    let album: String?
    let genre: String?
    let date: String?
    let duration: TimeInterval?
    let fileSize: String?
    let codec: String?
    let resolution: MediaResolution?
    let artworkURL: String?

    // Computed display properties
    var displayTitle: String { title ?? "Unknown" }
    var displayArtist: String { artist ?? "Unknown Artist" }
    var hasMetadata: Bool { title != nil || artist != nil || album != nil }
}
