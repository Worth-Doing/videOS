import SwiftUI

@MainActor
final class AppState: ObservableObject {
    let engine: PlayerEngine
    let libraryManager: LibraryManager
    let playlistManager: PlaylistManager
    let bookmarkService: BookmarkService
    let streamService: StreamService
    let playerVM: PlayerViewModel
    let libraryVM: LibraryViewModel
    let playlistVM: PlaylistViewModel

    init() {
        let engine = PlayerEngine()
        let libraryManager = LibraryManager()
        let playlistManager = PlaylistManager()
        let bookmarkService = BookmarkService()
        let streamService = StreamService()

        self.engine = engine
        self.libraryManager = libraryManager
        self.playlistManager = playlistManager
        self.bookmarkService = bookmarkService
        self.streamService = streamService

        self.playerVM = PlayerViewModel(
            engine: engine,
            bookmarkService: bookmarkService,
            libraryManager: libraryManager
        )
        self.playerVM.playlistManager = playlistManager
        self.libraryVM = LibraryViewModel(libraryManager: libraryManager)
        self.playlistVM = PlaylistViewModel(
            playlistManager: playlistManager,
            libraryManager: libraryManager
        )
    }
}

@main
struct VideOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup {
            MainWindow(
                playerVM: state.playerVM,
                libraryVM: state.libraryVM,
                playlistVM: state.playlistVM,
                streamService: state.streamService
            )
            .onAppear {
                appDelegate.playerViewModel = state.playerVM
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open File...") {
                    state.playerVM.openFile()
                }
                .keyboardShortcut("o")

                Button("Open URL...") {}
                    .keyboardShortcut("u")

                Divider()
            }

            CommandMenu("Playback") {
                Button(state.engine.isPlaying ? "Pause" : "Play") {
                    state.playerVM.togglePlay()
                }
                .keyboardShortcut(" ", modifiers: [])

                Divider()

                Button("Seek Forward 10s") {
                    state.playerVM.seekRelative(seconds: AppConstants.seekInterval)
                }
                .keyboardShortcut(.rightArrow, modifiers: [])

                Button("Seek Backward 10s") {
                    state.playerVM.seekRelative(seconds: -AppConstants.seekInterval)
                }
                .keyboardShortcut(.leftArrow, modifiers: [])

                Divider()

                Button("Increase Speed") {
                    state.playerVM.cycleSpeedUp()
                }
                .keyboardShortcut("]", modifiers: [])

                Button("Decrease Speed") {
                    state.playerVM.cycleSpeedDown()
                }
                .keyboardShortcut("[", modifiers: [])

                Button("Reset Speed") {
                    state.playerVM.resetSpeed()
                }
                .keyboardShortcut("=", modifiers: [])

                Divider()

                Button("Volume Up") {
                    state.playerVM.adjustVolume(by: AppConstants.volumeStep)
                }
                .keyboardShortcut(.upArrow, modifiers: [])

                Button("Volume Down") {
                    state.playerVM.adjustVolume(by: -AppConstants.volumeStep)
                }
                .keyboardShortcut(.downArrow, modifiers: [])

                Button("Toggle Mute") {
                    state.playerVM.toggleMute()
                }
                .keyboardShortcut("m", modifiers: [])
            }

            CommandMenu("View") {
                Button("Toggle Sidebar") {
                    state.playerVM.showSidebar.toggle()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Button("Toggle Fullscreen") {
                    state.playerVM.toggleFullscreen()
                }
                .keyboardShortcut("f")
            }
        }

        Settings {
            SettingsView()
        }
    }
}
