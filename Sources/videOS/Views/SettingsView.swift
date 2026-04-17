import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage("videOS.resumePlayback") private var resumePlayback = true
    @AppStorage("videOS.controlBarAutoHide") private var controlBarAutoHide = true
    @AppStorage("videOS.controlBarAutoHideDelay") private var autoHideDelay = 3.0
    @AppStorage("videOS.hardwareAcceleration") private var hwAccel = true
    @AppStorage("videOS.defaultPlaybackSpeed") private var defaultPlaybackSpeed = 1.0
    @AppStorage("videOS.defaultVolume") private var defaultVolume = 100
    @AppStorage("videOS.autoScanOnLaunch") private var autoScanOnLaunch = false
    @AppStorage("videOS.showHiddenFiles") private var showHiddenFiles = false

    @State private var watchedFolders: [String] = Defaults.stringArray(for: .libraryPaths)

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            playbackTab
                .tabItem {
                    Label("Playback", systemImage: "play.circle")
                }

            libraryTab
                .tabItem {
                    Label("Library", systemImage: "folder")
                }

            shortcutsTab
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
        }
        .frame(width: 520, height: 420)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section("Appearance") {
                LabeledContent("Theme") {
                    Picker("", selection: .constant("System")) {
                        Text("System").tag("System")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    .labelsHidden()
                }

                LabeledContent("Default sidebar section") {
                    Picker("", selection: .constant(SidebarSection.library)) {
                        ForEach(SidebarSection.allCases, id: \.self) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .frame(width: 140)
                    .labelsHidden()
                }
            }

            Section("Controls") {
                Toggle("Auto-hide controls during playback", isOn: $controlBarAutoHide)

                if controlBarAutoHide {
                    LabeledContent("Hide delay") {
                        HStack(spacing: 8) {
                            Slider(value: $autoHideDelay, in: 1...10, step: 0.5)
                                .frame(width: 150)
                            Text(String(format: "%.1fs", autoHideDelay))
                                .monospacedDigit()
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Playback Tab

    private var playbackTab: some View {
        Form {
            Section("Playback") {
                Toggle("Resume from last position", isOn: $resumePlayback)

                LabeledContent("Default playback speed") {
                    Picker("", selection: $defaultPlaybackSpeed) {
                        ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                            Text(String(format: "%.2gx", speed)).tag(speed)
                        }
                    }
                    .frame(width: 100)
                    .labelsHidden()
                }

                LabeledContent("Default volume") {
                    HStack(spacing: 8) {
                        Slider(
                            value: Binding(
                                get: { Double(defaultVolume) },
                                set: { defaultVolume = Int($0) }
                            ),
                            in: 0...150,
                            step: 5
                        )
                        .frame(width: 150)
                        Text("\(defaultVolume)%")
                            .monospacedDigit()
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }

            Section("Performance") {
                Toggle("Hardware acceleration", isOn: $hwAccel)

                LabeledContent("Audio output device") {
                    Picker("", selection: .constant("System Default")) {
                        Text("System Default").tag("System Default")
                    }
                    .frame(width: 180)
                    .labelsHidden()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Library Tab

    private var libraryTab: some View {
        Form {
            Section("Watched Folders") {
                if watchedFolders.isEmpty {
                    HStack {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text("No watched folders configured")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } else {
                    ForEach(watchedFolders, id: \.self) { folder in
                        HStack {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.blue)
                            Text(folder)
                                .font(.system(size: 12))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button {
                                watchedFolders.removeAll { $0 == folder }
                                Defaults.set(watchedFolders, for: .libraryPaths)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        let path = url.path
                        if !watchedFolders.contains(path) {
                            watchedFolders.append(path)
                            Defaults.set(watchedFolders, for: .libraryPaths)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11))
                        Text("Add Folder")
                            .font(.system(size: 12))
                    }
                }
            }

            Section("Scanning") {
                Toggle("Auto-scan on launch", isOn: $autoScanOnLaunch)
                Toggle("Show hidden files", isOn: $showHiddenFiles)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Shortcuts Tab

    private var shortcutsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Keyboard Shortcuts")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                shortcutSection("Playback", shortcuts: [
                    ("Space", "Play / Pause"),
                    ("[ / ]", "Decrease / Increase Speed"),
                    ("=", "Reset Speed"),
                ])

                shortcutSection("Seeking", shortcuts: [
                    ("\u{2190} / \u{2192}", "Seek Backward / Forward 10s"),
                    ("Shift + \u{2190} / \u{2192}", "Seek Backward / Forward 30s"),
                    ("Option + \u{2190} / \u{2192}", "Seek Backward / Forward 5s"),
                ])

                shortcutSection("Audio", shortcuts: [
                    ("\u{2191} / \u{2193}", "Volume Up / Down"),
                    ("M", "Toggle Mute"),
                ])

                shortcutSection("Navigation", shortcuts: [
                    ("Cmd + N", "Next Track"),
                    ("Cmd + P", "Previous Track"),
                    ("Cmd + F", "Toggle Fullscreen"),
                ])

                shortcutSection("Other", shortcuts: [
                    ("Cmd + I", "Show Media Info"),
                    ("Cmd + O", "Open File"),
                ])
            }
        }
    }

    private func shortcutSection(_ title: String, shortcuts: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

            ForEach(Array(shortcuts.enumerated()), id: \.offset) { index, shortcut in
                HStack {
                    Text(shortcut.0)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .frame(width: 160, alignment: .trailing)

                    Text(shortcut.1)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(index % 2 == 0 ? Color.clear : Color.primary.opacity(0.02))
            }
        }
    }
}
