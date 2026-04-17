import Foundation

enum AppConstants {
    static let controlHideDelay: UInt64 = 3_000_000_000
    static let maxRecentStreams = 50
    static let resumeMinPosition: Float = 0.02
    static let resumeMaxPosition: Float = 0.95
    static let positionSaveInterval: TimeInterval = 5
    static let seekInterval: Double = 10
    static let seekIntervalLarge: Double = 30
    static let seekIntervalSmall: Double = 5
    static let volumeStep = 5
    static let maxVolume = 200
}
