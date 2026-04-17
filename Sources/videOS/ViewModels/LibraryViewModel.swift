import Foundation
import Combine
import AppKit

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var filteredItems: [MediaItem] = []
    @Published var selectedItemIDs: Set<UUID> = []
    @Published var sortOrder: SortOrder = .name
    @Published var viewMode: ViewMode = .list

    let libraryManager: LibraryManager
    private var cancellables = Set<AnyCancellable>()

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case dateAdded = "Date Added"
        case lastPlayed = "Last Played"
        case duration = "Duration"
    }

    enum ViewMode: String, CaseIterable {
        case list = "List"
        case grid = "Grid"
    }

    init(libraryManager: LibraryManager) {
        self.libraryManager = libraryManager
        setupSearch()
    }

    private func setupSearch() {
        Publishers.CombineLatest3(
            libraryManager.$items,
            $searchQuery.debounce(for: .milliseconds(200), scheduler: DispatchQueue.main),
            $sortOrder
        )
        .map { items, query, sort in
            var result = query.isEmpty ? items : items.filter {
                $0.title.localizedCaseInsensitiveContains(query)
            }
            switch sort {
            case .name:
                result.sort { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
            case .dateAdded:
                result.sort { $0.addedDate > $1.addedDate }
            case .lastPlayed:
                result.sort { ($0.lastPlayedDate ?? .distantPast) > ($1.lastPlayedDate ?? .distantPast) }
            case .duration:
                result.sort { ($0.duration ?? 0) > ($1.duration ?? 0) }
            }
            return result
        }
        .assign(to: &$filteredItems)
    }

    func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true

        guard panel.runModal() == .OK else { return }
        libraryManager.scan(directories: panel.urls)
    }

    func removeSelected() {
        libraryManager.remove(ids: selectedItemIDs)
        selectedItemIDs.removeAll()
    }
}
