import Foundation
import Combine

@MainActor
final class StreamService: ObservableObject {
    @Published var recentStreams: [StreamEntry] = []

    private let storageURL = Defaults.appSupportURL.appendingPathComponent("streams.json")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    struct StreamEntry: Codable, Identifiable, Hashable {
        let id: UUID
        var url: URL
        var title: String
        var lastUsed: Date

        init(url: URL, title: String? = nil) {
            self.id = UUID()
            self.url = url
            self.title = title ?? url.host ?? url.absoluteString
            self.lastUsed = Date()
        }
    }

    init() {
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    func validate(urlString: String) -> URL? {
        guard let url = URL(string: urlString) else { return nil }
        let supportedSchemes = ["http", "https", "rtsp", "rtp", "udp", "mms", "mmsh", "ftp"]
        guard let scheme = url.scheme?.lowercased(), supportedSchemes.contains(scheme) else { return nil }
        return url
    }

    func addToRecent(url: URL, title: String? = nil) {
        recentStreams.removeAll { $0.url == url }
        recentStreams.insert(StreamEntry(url: url, title: title), at: 0)
        if recentStreams.count > AppConstants.maxRecentStreams {
            recentStreams = Array(recentStreams.prefix(AppConstants.maxRecentStreams))
        }
        save()
    }

    func removeStream(id: UUID) {
        recentStreams.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        recentStreams.removeAll()
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        guard let data = try? Data(contentsOf: storageURL) else { return }
        recentStreams = (try? decoder.decode([StreamEntry].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? encoder.encode(recentStreams) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}
