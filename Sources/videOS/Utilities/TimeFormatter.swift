import Foundation

enum TimeFormatter {
    static func format(milliseconds ms: Int64) -> String {
        format(seconds: Double(ms) / 1000.0)
    }

    static func format(seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "00:00" }

        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    static func formatDetailed(seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "00:00.000" }

        let totalSeconds = Int(seconds)
        let ms = Int((seconds - Double(totalSeconds)) * 1000)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d.%03d", hours, minutes, secs, ms)
        }
        return String(format: "%02d:%02d.%03d", minutes, secs, ms)
    }
}
