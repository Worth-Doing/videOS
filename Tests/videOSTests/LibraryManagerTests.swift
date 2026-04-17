import XCTest
@testable import videOS

final class LibraryManagerTests: XCTestCase {
    func testPlaylistOperations() {
        var playlist = Playlist(name: "Test")
        let id1 = UUID()
        let id2 = UUID()

        XCTAssertTrue(playlist.isEmpty)
        XCTAssertEqual(playlist.count, 0)

        playlist.add(id1)
        XCTAssertEqual(playlist.count, 1)

        playlist.add(id1) // duplicate
        XCTAssertEqual(playlist.count, 1)

        playlist.add(id2)
        XCTAssertEqual(playlist.count, 2)

        playlist.remove(id1)
        XCTAssertEqual(playlist.count, 1)
        XCTAssertEqual(playlist.itemIDs.first, id2)
    }

    func testBookmarkFiltering() {
        let mediaID = UUID()
        let otherID = UUID()

        let bookmarks: [Bookmark] = [
            Bookmark(mediaID: mediaID, label: "Scene 1", timestamp: 10),
            Bookmark(mediaID: otherID, label: "Other", timestamp: 20),
            Bookmark(mediaID: mediaID, label: "Scene 2", timestamp: 30),
            Bookmark(mediaID: mediaID, label: "Scene 0", timestamp: 5),
        ]

        let filtered = bookmarks.forMedia(mediaID)
        XCTAssertEqual(filtered.count, 3)
        XCTAssertEqual(filtered[0].label, "Scene 0")
        XCTAssertEqual(filtered[1].label, "Scene 1")
        XCTAssertEqual(filtered[2].label, "Scene 2")
    }

    func testMediaExtensions() {
        XCTAssertTrue(MediaItem.videoExtensions.contains("mp4"))
        XCTAssertTrue(MediaItem.videoExtensions.contains("mkv"))
        XCTAssertTrue(MediaItem.audioExtensions.contains("flac"))
        XCTAssertTrue(MediaItem.subtitleExtensions.contains("srt"))
        XCTAssertFalse(MediaItem.videoExtensions.contains("txt"))
    }
}
