import Foundation

struct AudioTrack: Identifiable, Hashable {
    let id: Int
    let name: String

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }

    static let disabled = AudioTrack(id: -1, name: "Disabled")
}
