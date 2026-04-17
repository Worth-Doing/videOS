import Foundation
import Combine

@MainActor
final class LibraryManager: ObservableObject {
    @Published var items: [MediaItem] = []
    @Published var recentItems: [MediaItem] = []
    @Published var isScanning = false

    private let storageURL = Defaults.appSupportURL.appendingPathComponent("library.json")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    func scan(directories: [URL]) {
        isScanning = true
        let existingURLs = Set(items.map(\.url))

        Task.detached { [weak self] in
            var newItems: [MediaItem] = []
            for dir in directories {
                let files = FileScanner.scan(directory: dir)
                for url in files where !existingURLs.contains(url) {
                    var item = MediaItem(url: url)
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                       let size = attrs[.size] as? Int64 {
                        item.fileSize = size
                    }
                    newItems.append(item)
                }
            }

            await MainActor.run {
                guard let self else { return }
                self.items.append(contentsOf: newItems)
                self.isScanning = false
                self.save()
            }
        }
    }

    func add(url: URL) {
        guard !items.contains(where: { $0.url == url }) else { return }
        items.append(MediaItem(url: url))
        save()
    }

    func add(urls: [URL]) {
        let existingURLs = Set(items.map(\.url))
        let newItems = urls.filter { !existingURLs.contains($0) }.map { MediaItem(url: $0) }
        items.append(contentsOf: newItems)
        save()
    }

    func remove(item: MediaItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func remove(ids: Set<UUID>) {
        items.removeAll { ids.contains($0.id) }
        save()
    }

    func markPlayed(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].lastPlayedDate = Date()
        items[index].playCount += 1
        updateRecents()
        save()
    }

    func item(for id: UUID) -> MediaItem? {
        items.first { $0.id == id }
    }

    func search(query: String) -> [MediaItem] {
        guard !query.isEmpty else { return items }
        let lowered = query.lowercased()
        return items.filter { $0.title.lowercased().contains(lowered) }
    }

    private func updateRecents() {
        recentItems = items
            .filter { $0.lastPlayedDate != nil }
            .sorted { ($0.lastPlayedDate ?? .distantPast) > ($1.lastPlayedDate ?? .distantPast) }
            .prefix(20)
            .map { $0 }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        guard let data = try? Data(contentsOf: storageURL) else { return }
        items = (try? decoder.decode([MediaItem].self, from: data)) ?? []
        updateRecents()
    }

    func save() {
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}
