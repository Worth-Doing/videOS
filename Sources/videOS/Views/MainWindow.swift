import SwiftUI

struct MainWindow: View {
    @ObservedObject var playerVM: PlayerViewModel
    @ObservedObject var libraryVM: LibraryViewModel
    @ObservedObject var playlistVM: PlaylistViewModel
    @ObservedObject var streamService: StreamService

    @State private var selectedSection: SidebarSection = .library

    var body: some View {
        HSplitView {
            if playerVM.showSidebar {
                Sidebar(
                    selectedSection: $selectedSection,
                    playlistManager: playlistVM.playlistManager,
                    streamService: streamService,
                    libraryManager: libraryVM.libraryManager
                )
                .frame(minWidth: 180, maxWidth: 280)
            }

            VStack(spacing: 0) {
                if playerVM.currentItem != nil || selectedSection == .library {
                    GeometryReader { geo in
                        VStack(spacing: 0) {
                            if playerVM.currentItem != nil {
                                PlayerContainerView(viewModel: playerVM)
                                    .frame(minHeight: geo.size.height * 0.4)
                            }

                            if selectedSection != .library || playerVM.currentItem == nil {
                                sectionContent
                            }
                        }
                    }
                } else {
                    sectionContent
                }
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .background(Color(nsColor: .windowBackgroundColor))
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .library:
            LibraryView(viewModel: libraryVM) { item in
                playerVM.open(item: item)
            }
        case .playlists:
            PlaylistView(viewModel: playlistVM) { item in
                playerVM.open(item: item)
            }
        case .streams:
            StreamInputView(streamService: streamService) { url in
                playerVM.openURL(url)
            }
        case .bookmarks:
            BookmarkListView(
                bookmarkService: playerVM.bookmarkService,
                currentMediaID: playerVM.currentItem?.id,
                currentTimestamp: TimeInterval(playerVM.engine.currentTime) / 1000.0,
                onJump: { bookmark in playerVM.jumpToBookmark(bookmark) }
            )
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
                guard let data = data as? Data,
                      let urlString = String(data: data, encoding: .utf8),
                      let url = URL(string: urlString) else { return }

                DispatchQueue.main.async {
                    if url.hasDirectoryPath {
                        libraryVM.libraryManager.scan(directories: [url])
                    } else {
                        playerVM.openURL(url)
                    }
                }
            }
        }
        return true
    }
}

struct BookmarkListView: View {
    @ObservedObject var bookmarkService: BookmarkService
    let currentMediaID: UUID?
    var currentTimestamp: TimeInterval
    var onJump: (Bookmark) -> Void

    @State private var newLabel = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Bookmarks")
                    .font(.headline)
                Spacer()
            }
            .padding(12)

            Divider()

            if let mediaID = currentMediaID {
                HStack {
                    TextField("Bookmark label", text: $newLabel)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addBookmark(mediaID: mediaID) }

                    Button("Add") { addBookmark(mediaID: mediaID) }
                        .disabled(newLabel.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(12)

                let bookmarks = bookmarkService.bookmarks(for: mediaID)
                if bookmarks.isEmpty {
                    VStack {
                        Spacer()
                        Text("No bookmarks for current media")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    List(bookmarks) { bookmark in
                        HStack {
                            Image(systemName: "bookmark.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)

                            VStack(alignment: .leading) {
                                Text(bookmark.label)
                                    .font(.system(size: 13))
                                Text(TimeFormatter.format(seconds: bookmark.timestamp))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { onJump(bookmark) }
                        .contextMenu {
                            Button("Jump to") { onJump(bookmark) }
                            Button("Delete", role: .destructive) {
                                bookmarkService.removeBookmark(id: bookmark.id)
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "bookmark")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundStyle(.secondary)
                    Text("Open a video to manage bookmarks")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    private func addBookmark(mediaID: UUID) {
        let label = newLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty else { return }
        _ = bookmarkService.addBookmark(mediaID: mediaID, label: label, timestamp: currentTimestamp)
        newLabel = ""
    }
}
