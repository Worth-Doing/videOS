import Foundation

struct Bookmark: Codable, Identifiable, Hashable {
    let id: UUID
    let mediaID: UUID
    var label: String
    var timestamp: TimeInterval
    var createdDate: Date

    init(mediaID: UUID, label: String, timestamp: TimeInterval) {
        self.id = UUID()
        self.mediaID = mediaID
        self.label = label
        self.timestamp = timestamp
        self.createdDate = Date()
    }
}

extension Array where Element == Bookmark {
    func forMedia(_ mediaID: UUID) -> [Bookmark] {
        filter { $0.mediaID == mediaID }.sorted { $0.timestamp < $1.timestamp }
    }
}
