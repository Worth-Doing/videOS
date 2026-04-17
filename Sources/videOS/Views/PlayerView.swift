import SwiftUI
import AppKit

struct PlayerView: NSViewRepresentable {
    let engine: PlayerEngine

    func makeNSView(context: Context) -> NSView {
        let view = PlayerNSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        engine.setVideoView(view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

final class PlayerNSView: NSView {
    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { false }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        dirtyRect.fill()
    }
}

struct PlayerContainerView: View {
    @ObservedObject var viewModel: PlayerViewModel

    @State private var showMediaInfo = false
    @State private var mediaInfoDismissTask: Task<Void, Never>?
    @State private var dismissedError = false

    var body: some View {
        ZStack {
            Color.black

            PlayerView(engine: viewModel.engine)
                .onTapGesture(count: 2) {
                    viewModel.toggleFullscreen()
                }
                .onTapGesture(count: 1) {
                    viewModel.togglePlay()
                }

            // Empty state
            if viewModel.engine.state == .idle {
                emptyState
            }

            // Buffering overlay
            if case .buffering(let progress) = viewModel.engine.state, progress < 100 {
                bufferingOverlay(progress: progress)
            }

            // Error banner
            if viewModel.engine.state == .error && !dismissedError {
                VStack {
                    errorBanner
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Media info overlay
            if showMediaInfo {
                VStack {
                    HStack {
                        Spacer()
                        mediaInfoView
                            .padding(.top, 12)
                            .padding(.trailing, 12)
                    }
                    Spacer()
                }
                .transition(.opacity)
            }

            // Controls
            if viewModel.showControls {
                VStack {
                    Spacer()
                    ControlBar(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .padding(.bottom, 8)
                .padding(.horizontal, 16)
            }
        }
        .onHover { _ in
            viewModel.onMouseMove()
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showControls)
        .animation(.easeInOut(duration: 0.25), value: showMediaInfo)
        .animation(.easeInOut(duration: 0.25), value: dismissedError)
        .onChange(of: viewModel.engine.state) { newState in
            if newState == .error {
                dismissedError = false
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.12),
                    Color(red: 0.02, green: 0.02, blue: 0.06),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 32) {
                Spacer()

                // App branding
                VStack(spacing: 12) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 56, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), .purple.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("videOS")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white.opacity(0.9), .white.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Open media to start playing")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.35))
                }

                // Action pills
                HStack(spacing: 16) {
                    actionPill(icon: "doc.fill", title: "Open File", shortcut: "Cmd+O") {
                        viewModel.openFile()
                    }

                    actionPill(icon: "globe", title: "Open URL", shortcut: "Cmd+U") {
                        // Handled via sidebar streams section
                    }

                    VStack(spacing: 6) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.35))
                        Text("Drag Media Here")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .frame(width: 100, height: 70)
                    .background(.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1, antialiased: true)
                    )
                }

                Spacer()
            }
        }
    }

    private func actionPill(icon: String, title: String, shortcut: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.6))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                Text(shortcut)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.25))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(width: 100, height: 70)
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1, antialiased: true)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    // MARK: - Buffering Overlay

    private func bufferingOverlay(progress: Float) -> some View {
        VStack(spacing: 10) {
            ProgressView()
                .controlSize(.regular)
                .tint(.white)

            Text("Buffering")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.15))
                    Capsule()
                        .fill(.white.opacity(0.5))
                        .frame(width: geo.size.width * CGFloat(progress / 100))
                }
            }
            .frame(width: 100, height: 3)

            Text("\(Int(progress))%")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(28)
        .glassPanel(cornerRadius: 16)
    }

    // MARK: - Error Banner

    private var errorBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.red)

            Text("Playback error occurred")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))

            Spacer()

            Button {
                withAnimation {
                    dismissedError = true
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.red.opacity(0.15))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.red.opacity(0.3), lineWidth: 0.5)
        )
    }

    // MARK: - Media Info

    private var mediaInfoView: some View {
        Group {
            if let item = viewModel.currentItem {
                MediaInfoOverlay(
                    title: item.title,
                    details: buildMediaInfoDetails(for: item),
                    onDismiss: {
                        showMediaInfo = false
                        mediaInfoDismissTask?.cancel()
                    }
                )
            }
        }
    }

    private func buildMediaInfoDetails(for item: MediaItem) -> [(String, String)] {
        var details: [(String, String)] = []

        details.append(("Format", item.fileExtension.uppercased()))

        if let duration = item.duration {
            details.append(("Duration", TimeFormatter.format(seconds: duration)))
        }

        if let res = item.resolution {
            details.append(("Resolution", "\(res.width) x \(res.height) (\(res.displayString))"))
        }

        if let codec = item.codec {
            details.append(("Codec", codec))
        }

        if let size = item.fileSize {
            details.append(("Size", formatFileSize(size)))
        }

        return details
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
