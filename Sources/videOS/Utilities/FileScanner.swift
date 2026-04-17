import Foundation

enum FileScanner {
    static let supportedExtensions = MediaItem.videoExtensions.union(MediaItem.audioExtensions)

    static func scan(directory: URL, recursive: Bool = true) -> [URL] {
        let manager = FileManager.default
        guard let enumerator = manager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: recursive ? [.skipsHiddenFiles] : [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else {
            return []
        }

        var results: [URL] = []
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            if supportedExtensions.contains(ext) {
                results.append(fileURL)
            }
        }
        return results.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    static func findSidecarSubtitles(for mediaURL: URL) -> [URL] {
        let directory = mediaURL.deletingLastPathComponent()
        let baseName = mediaURL.deletingPathExtension().lastPathComponent
        let manager = FileManager.default

        guard let contents = try? manager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        return contents.filter { url in
            let ext = url.pathExtension.lowercased()
            let name = url.deletingPathExtension().lastPathComponent
            return MediaItem.subtitleExtensions.contains(ext) && name.hasPrefix(baseName)
        }
    }
}
