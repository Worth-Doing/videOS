import Foundation

enum Defaults {
    static let suiteName = "com.videOS.app"

    private static let defaults = UserDefaults(suiteName: suiteName) ?? .standard

    enum Key: String {
        case volume = "videOS.volume"
        case lastOpenedURL = "videOS.lastOpenedURL"
        case sidebarVisible = "videOS.sidebarVisible"
        case controlBarAutoHide = "videOS.controlBarAutoHide"
        case controlBarAutoHideDelay = "videOS.controlBarAutoHideDelay"
        case resumePlayback = "videOS.resumePlayback"
        case hardwareAcceleration = "videOS.hardwareAcceleration"
        case libraryPaths = "videOS.libraryPaths"
    }

    static func float(for key: Key, default defaultValue: Float = 0) -> Float {
        let val = defaults.float(forKey: key.rawValue)
        return val == 0 ? defaultValue : val
    }

    static func set(_ value: Float, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    static func bool(for key: Key, default defaultValue: Bool = false) -> Bool {
        if defaults.object(forKey: key.rawValue) == nil { return defaultValue }
        return defaults.bool(forKey: key.rawValue)
    }

    static func set(_ value: Bool, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    static func double(for key: Key, default defaultValue: Double = 0) -> Double {
        let val = defaults.double(forKey: key.rawValue)
        return val == 0 ? defaultValue : val
    }

    static func set(_ value: Double, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    static func string(for key: Key) -> String? {
        defaults.string(forKey: key.rawValue)
    }

    static func set(_ value: String?, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    static func stringArray(for key: Key) -> [String] {
        defaults.stringArray(forKey: key.rawValue) ?? []
    }

    static func set(_ value: [String], for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    static let appSupportURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let url = base.appendingPathComponent("videOS")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()
}
