import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var playerViewModel: PlayerViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {}

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        playerViewModel?.openURL(url)
    }
}
