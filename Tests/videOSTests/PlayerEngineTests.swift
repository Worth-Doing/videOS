import XCTest
@testable import videOS

final class PlayerEngineTests: XCTestCase {
    func testTimeFormatterSeconds() {
        XCTAssertEqual(TimeFormatter.format(seconds: 0), "00:00")
        XCTAssertEqual(TimeFormatter.format(seconds: 65), "01:05")
        XCTAssertEqual(TimeFormatter.format(seconds: 3661), "1:01:01")
        XCTAssertEqual(TimeFormatter.format(seconds: -1), "00:00")
    }

    func testTimeFormatterMilliseconds() {
        XCTAssertEqual(TimeFormatter.format(milliseconds: 0), "00:00")
        XCTAssertEqual(TimeFormatter.format(milliseconds: 65000), "01:05")
        XCTAssertEqual(TimeFormatter.format(milliseconds: 3661000), "1:01:01")
    }

    func testMediaItemCreation() {
        let url = URL(fileURLWithPath: "/test/movie.mp4")
        let item = MediaItem(url: url)

        XCTAssertEqual(item.title, "movie")
        XCTAssertTrue(item.isLocal)
        XCTAssertFalse(item.isStream)
        XCTAssertEqual(item.fileExtension, "mp4")
        XCTAssertEqual(item.mediaType, .video)
        XCTAssertEqual(item.playCount, 0)
    }

    func testMediaItemStream() {
        let url = URL(string: "http://example.com/stream.m3u8")!
        let item = MediaItem(url: url)

        XCTAssertFalse(item.isLocal)
        XCTAssertTrue(item.isStream)
        XCTAssertEqual(item.mediaType, .stream)
    }

    func testMediaItemAudio() {
        let url = URL(fileURLWithPath: "/test/song.flac")
        let item = MediaItem(url: url)
        XCTAssertEqual(item.mediaType, .audio)
    }

    func testPlaybackState() {
        var store = PlaybackStateStore()
        let id = UUID()

        store.save(mediaID: id, position: 0.5, timestamp: 300)
        let state = store.get(mediaID: id)

        XCTAssertNotNil(state)
        XCTAssertEqual(state?.position, 0.5)
        XCTAssertTrue(state?.shouldResume == true)

        store.clear(mediaID: id)
        XCTAssertNil(store.get(mediaID: id))
    }

    func testPlaybackStateEdgeCases() {
        let beginning = PlaybackState(mediaID: UUID(), position: 0.01, timestamp: 1)
        XCTAssertFalse(beginning.shouldResume)

        let end = PlaybackState(mediaID: UUID(), position: 0.98, timestamp: 5000)
        XCTAssertFalse(end.shouldResume)

        let middle = PlaybackState(mediaID: UUID(), position: 0.5, timestamp: 2500)
        XCTAssertTrue(middle.shouldResume)
    }

    func testResolutionDisplay() {
        XCTAssertEqual(MediaResolution(width: 3840, height: 2160).displayString, "4K")
        XCTAssertEqual(MediaResolution(width: 1920, height: 1080).displayString, "1080p")
        XCTAssertEqual(MediaResolution(width: 1280, height: 720).displayString, "720p")
        XCTAssertEqual(MediaResolution(width: 640, height: 480).displayString, "480p")
        XCTAssertEqual(MediaResolution(width: 320, height: 240).displayString, "320x240")
    }
}
