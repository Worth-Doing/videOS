import Foundation

struct Playlist: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var itemIDs: [UUID]
    var createdDate: Date
    var modifiedDate: Date

    init(name: String, itemIDs: [UUID] = []) {
        self.id = UUID()
        self.name = name
        self.itemIDs = itemIDs
        self.createdDate = Date()
        self.modifiedDate = Date()
    }

    var count: Int { itemIDs.count }
    var isEmpty: Bool { itemIDs.isEmpty }

    mutating func add(_ itemID: UUID) {
        guard !itemIDs.contains(itemID) else { return }
        itemIDs.append(itemID)
        modifiedDate = Date()
    }

    mutating func remove(_ itemID: UUID) {
        itemIDs.removeAll { $0 == itemID }
        modifiedDate = Date()
    }

    mutating func move(from source: IndexSet, to destination: Int) {
        itemIDs.move(fromOffsets: source, toOffset: destination)
        modifiedDate = Date()
    }
}
