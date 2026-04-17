import Foundation

struct SubtitleTrack: Identifiable, Hashable {
    let id: Int
    let name: String
    let isExternal: Bool
    let filePath: String?

    init(id: Int, name: String, isExternal: Bool = false, filePath: String? = nil) {
        self.id = id
        self.name = name
        self.isExternal = isExternal
        self.filePath = filePath
    }

    static let disabled = SubtitleTrack(id: -1, name: "Disabled")
}
