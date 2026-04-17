import Foundation
import Combine

@MainActor
final class YouTubeService: ObservableObject {
    @Published var downloads: [YouTubeDownload] = []
    @Published var isCheckingURL = false

    private let downloadDir: URL = {
        let dir = Defaults.appSupportURL.appendingPathComponent("YouTube")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    struct YouTubeDownload: Identifiable {
        let id = UUID()
        var url: URL
        var title: String
        var status: Status
        var progress: Double
        var localFile: URL?
        var thumbnail: String?
        var duration: String?
        var resolution: String?
        var error: String?
        var task: Process?

        enum Status: Equatable {
            case queued
            case fetching
            case downloading
            case complete
            case failed
        }
    }

    static let supportedHosts: Set<String> = [
        "youtube.com", "www.youtube.com", "m.youtube.com",
        "youtu.be",
        "youtube-nocookie.com", "www.youtube-nocookie.com",
    ]

    static func isYouTubeURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased() else { return false }
        return supportedHosts.contains(host)
    }

    static func ytDlpPath() -> String? {
        var paths = [String]()
        // Bundled in app
        if let bundled = Bundle.main.executableURL?.deletingLastPathComponent()
            .appendingPathComponent("yt-dlp").path {
            paths.append(bundled)
        }
        paths.append(contentsOf: [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp",
        ])
        return paths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static var isAvailable: Bool {
        ytDlpPath() != nil
    }

    func fetchInfo(urlString: String) async -> (title: String, duration: String?, thumbnail: String?)? {
        guard let ytDlp = Self.ytDlpPath() else { return nil }

        isCheckingURL = true
        defer { isCheckingURL = false }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytDlp)
        process.arguments = [
            "--dump-json",
            "--no-download",
            "--no-warnings",
            urlString
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard process.terminationStatus == 0,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }

            let title = json["title"] as? String ?? "Unknown"
            let dur = json["duration"] as? Double
            let durString = dur.map { TimeFormatter.format(seconds: $0) }
            let thumb = json["thumbnail"] as? String

            return (title, durString, thumb)
        } catch {
            return nil
        }
    }

    func download(urlString: String, quality: VideoQuality = .best) {
        guard let ytDlp = Self.ytDlpPath() else {
            var dl = YouTubeDownload(
                url: URL(string: urlString)!,
                title: "Error",
                status: .failed,
                progress: 0,
                error: "yt-dlp not found. Install: brew install yt-dlp"
            )
            downloads.insert(dl, at: 0)
            return
        }

        let url = URL(string: urlString)!
        var dl = YouTubeDownload(
            url: url,
            title: urlString,
            status: .fetching,
            progress: 0
        )
        downloads.insert(dl, at: 0)
        let dlID = dl.id

        Task.detached { [weak self] in
            guard let self else { return }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: ytDlp)

            let outputTemplate = self.downloadDir.path + "/%(title)s.%(ext)s"

            var args = [
                "-f", quality.formatString,
                "--merge-output-format", "mp4",
                "--no-warnings",
                "--newline",
                "--print", "after_move:filepath",
                "-o", outputTemplate,
                urlString
            ]

            process.arguments = args

            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe

            await MainActor.run {
                self.updateDownload(dlID) { $0.status = .downloading }
            }

            do {
                try process.run()
            } catch {
                await MainActor.run {
                    self.updateDownload(dlID) {
                        $0.status = .failed
                        $0.error = error.localizedDescription
                    }
                }
                return
            }

            // Read output line by line for progress
            let handle = outPipe.fileHandleForReading
            var lastFilePath: String?

            let errHandle = errPipe.fileHandleForReading

            while process.isRunning {
                if let line = self.readLine(from: handle) {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

                    // Parse progress: [download]  45.2% of ...
                    if trimmed.contains("[download]") && trimmed.contains("%") {
                        if let pct = self.parseProgress(trimmed) {
                            await MainActor.run {
                                self.updateDownload(dlID) { $0.progress = pct }
                            }
                        }
                    }

                    // Parse title from [info] line or metadata
                    if trimmed.contains("[info]") && trimmed.contains(":") {
                        let titlePart = trimmed.components(separatedBy: ": ").dropFirst().joined(separator: ": ")
                        if !titlePart.isEmpty && titlePart.count > 3 {
                            await MainActor.run {
                                self.updateDownload(dlID) { $0.title = titlePart }
                            }
                        }
                    }

                    // Capture final file path (last non-empty line after download)
                    if !trimmed.isEmpty && !trimmed.hasPrefix("[") {
                        lastFilePath = trimmed
                    }
                }
            }

            // Read any remaining output
            let remaining = String(data: handle.readDataToEndOfFile(), encoding: .utf8) ?? ""
            for line in remaining.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && !trimmed.hasPrefix("[") {
                    lastFilePath = trimmed
                }
            }

            process.waitUntilExit()

            if process.terminationStatus == 0, let filePath = lastFilePath {
                let fileURL = URL(fileURLWithPath: filePath)
                let title = fileURL.deletingPathExtension().lastPathComponent

                await MainActor.run {
                    self.updateDownload(dlID) {
                        $0.status = .complete
                        $0.progress = 100
                        $0.localFile = fileURL
                        $0.title = title
                    }
                }
            } else {
                let errData = errHandle.readDataToEndOfFile()
                let errMsg = String(data: errData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: "\n").last ?? "Download failed"

                await MainActor.run {
                    self.updateDownload(dlID) {
                        $0.status = .failed
                        $0.error = errMsg
                    }
                }
            }
        }
    }

    func removeDownload(id: UUID) {
        downloads.removeAll { $0.id == id }
    }

    func clearCompleted() {
        downloads.removeAll { $0.status == .complete || $0.status == .failed }
    }

    private func updateDownload(_ id: UUID, update: (inout YouTubeDownload) -> Void) {
        guard let idx = downloads.firstIndex(where: { $0.id == id }) else { return }
        update(&downloads[idx])
    }

    private nonisolated func readLine(from handle: FileHandle) -> String? {
        var buffer = Data()
        while true {
            let byte = handle.readData(ofLength: 1)
            if byte.isEmpty { return buffer.isEmpty ? nil : String(data: buffer, encoding: .utf8) }
            if byte.first == UInt8(ascii: "\n") {
                return String(data: buffer, encoding: .utf8)
            }
            buffer.append(byte)
        }
    }

    private nonisolated func parseProgress(_ line: String) -> Double? {
        // Match patterns like "45.2%" or "100%"
        let pattern = #"(\d+\.?\d*)%"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let range = Range(match.range(at: 1), in: line),
              let value = Double(line[range]) else { return nil }
        return value
    }
}

enum VideoQuality: String, CaseIterable, Identifiable {
    case best = "Best"
    case hd1080 = "1080p"
    case hd720 = "720p"
    case sd480 = "480p"
    case audioOnly = "Audio Only"

    var id: String { rawValue }

    var formatString: String {
        switch self {
        case .best: return "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
        case .hd1080: return "bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[height<=1080]"
        case .hd720: return "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720]"
        case .sd480: return "bestvideo[height<=480][ext=mp4]+bestaudio[ext=m4a]/best[height<=480]"
        case .audioOnly: return "bestaudio[ext=m4a]/bestaudio"
        }
    }
}
