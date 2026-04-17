import XCTest
@testable import videOS

final class PlaylistManagerTests: XCTestCase {
    func testPlaylistMoveItems() {
        var playlist = Playlist(name: "Test")
        let ids = (0..<5).map { _ in UUID() }
        ids.forEach { playlist.add($0) }

        XCTAssertEqual(playlist.itemIDs, ids)

        playlist.move(from: IndexSet(integer: 0), to: 3)
        XCTAssertEqual(playlist.itemIDs[0], ids[1])
        XCTAssertEqual(playlist.itemIDs[2], ids[0])
    }

    func testStreamValidation() {
        let service = StreamServiceValidator()

        XCTAssertNotNil(service.validate(urlString: "http://example.com/stream"))
        XCTAssertNotNil(service.validate(urlString: "https://example.com/live.m3u8"))
        XCTAssertNotNil(service.validate(urlString: "rtsp://192.168.1.1:554/stream"))
        XCTAssertNil(service.validate(urlString: "not-a-url"))
        XCTAssertNil(service.validate(urlString: "file:///local/file"))
        XCTAssertNil(service.validate(urlString: ""))
    }

    func testTimeFormatterDetailed() {
        XCTAssertEqual(TimeFormatter.formatDetailed(seconds: 0), "00:00.000")
        XCTAssertEqual(TimeFormatter.formatDetailed(seconds: 1.5), "00:01.500")
        XCTAssertEqual(TimeFormatter.formatDetailed(seconds: 3661.123), "1:01:01.123")
    }
}

private struct StreamServiceValidator {
    func validate(urlString: String) -> URL? {
        guard let url = URL(string: urlString) else { return nil }
        let supportedSchemes = ["http", "https", "rtsp", "rtp", "udp", "mms", "mmsh", "ftp"]
        guard let scheme = url.scheme?.lowercased(), supportedSchemes.contains(scheme) else { return nil }
        return url
    }
}
