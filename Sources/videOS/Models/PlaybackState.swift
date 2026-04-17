import Foundation

struct PlaybackState: Codable, Identifiable {
    var id: UUID { mediaID }
    let mediaID: UUID
    var position: Float
    var timestamp: TimeInterval
    var lastUpdated: Date

    init(mediaID: UUID, position: Float, timestamp: TimeInterval) {
        self.mediaID = mediaID
        self.position = position
        self.timestamp = timestamp
        self.lastUpdated = Date()
    }

    var shouldResume: Bool {
        position > AppConstants.resumeMinPosition && position < AppConstants.resumeMaxPosition
    }
}

struct PlaybackStateStore: Codable {
    var states: [UUID: PlaybackState]

    init() {
        self.states = [:]
    }

    mutating func save(mediaID: UUID, position: Float, timestamp: TimeInterval) {
        states[mediaID] = PlaybackState(mediaID: mediaID, position: position, timestamp: timestamp)
    }

    func get(mediaID: UUID) -> PlaybackState? {
        states[mediaID]
    }

    mutating func clear(mediaID: UUID) {
        states.removeValue(forKey: mediaID)
    }
}
