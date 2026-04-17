import Foundation
import CLibVLC

struct MediaMetadata {
    var title: String?
    var artist: String?
    var album: String?
    var genre: String?
    var date: String?
    var duration: TimeInterval?
    var description: String?
    var artworkURL: String?
    var codec: String?
    var resolution: MediaResolution?
}

enum MetadataService {
    static func extract(from url: URL, vlcInstance: OpaquePointer?) -> MediaMetadata {
        guard let instance = vlcInstance else { return MediaMetadata() }

        let media: OpaquePointer?
        if url.isFileURL {
            media = libvlc_media_new_path(instance, url.path)
        } else {
            media = libvlc_media_new_location(instance, url.absoluteString)
        }
        guard let media else { return MediaMetadata() }
        defer { libvlc_media_release(media) }

        libvlc_media_parse_with_options(media, libvlc_media_parse_local, 3000)

        var meta = MediaMetadata()

        meta.title = getMeta(media, Int32(libvlc_meta_Title))
        meta.artist = getMeta(media, Int32(libvlc_meta_Artist))
        meta.album = getMeta(media, Int32(libvlc_meta_Album))
        meta.genre = getMeta(media, Int32(libvlc_meta_Genre))
        meta.date = getMeta(media, Int32(libvlc_meta_Date))
        meta.description = getMeta(media, Int32(libvlc_meta_Description))
        meta.artworkURL = getMeta(media, Int32(libvlc_meta_ArtworkURL))

        let durationMs = libvlc_media_get_duration(media)
        if durationMs > 0 {
            meta.duration = TimeInterval(durationMs) / 1000.0
        }

        return meta
    }

    private static func getMeta(_ media: OpaquePointer, _ type: Int32) -> String? {
        guard let cString = libvlc_media_get_meta(media, type) else { return nil }
        let value = String(cString: cString)
        free(cString)
        return value.isEmpty ? nil : value
    }

    static func fileSizeString(for url: URL) -> String? {
        guard url.isFileURL else { return nil }
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
