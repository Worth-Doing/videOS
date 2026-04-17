import SwiftUI

struct YouTubeView: View {
    @ObservedObject var youtubeService: YouTubeService
    var onPlay: (URL) -> Void

    @State private var urlString = ""
    @State private var selectedQuality: VideoQuality = .best
    @State private var videoInfo: (title: String, duration: String?, thumbnail: String?)?
    @State private var errorMessage: String?
    @State private var isPreviewing = false

    var body: some View {
        VStack(spacing: 0) {
            inputSection
            Divider()
            downloadsList
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.red)
                Text("YouTube")
                    .font(.system(size: 15, weight: .semibold))

                Spacer()

                if !YouTubeService.isAvailable {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text("yt-dlp not found")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                }
            }

            // URL input
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                TextField("Paste YouTube URL...", text: $urlString)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .onSubmit { previewVideo() }
                    .onChange(of: urlString) { newValue in
                        if !YouTubeService.isYouTubeURL(newValue) {
                            videoInfo = nil
                        }
                    }

                if !urlString.isEmpty {
                    Button {
                        urlString = ""
                        videoInfo = nil
                        errorMessage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.quaternary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        YouTubeService.isYouTubeURL(urlString)
                            ? .red.opacity(0.3)
                            : errorMessage != nil ? .red.opacity(0.5) : .clear,
                        lineWidth: 1
                    )
            )

            // Paste from clipboard button
            HStack(spacing: 8) {
                Button {
                    if let clip = NSPasteboard.general.string(forType: .string) {
                        urlString = clip
                        if YouTubeService.isYouTubeURL(clip) {
                            previewVideo()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 10))
                        Text("Paste")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)

                // Quality picker
                Picker("", selection: $selectedQuality) {
                    ForEach(VideoQuality.allCases) { q in
                        Text(q.rawValue).tag(q)
                    }
                }
                .frame(width: 110)
                .labelsHidden()

                Spacer()

                if youtubeService.isCheckingURL || isPreviewing {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Fetching info...")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    startDownload()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 11))
                        Text("Download & Play")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.small)
                .disabled(urlString.trimmingCharacters(in: .whitespaces).isEmpty || !YouTubeService.isAvailable)
            }

            // Video preview card
            if let info = videoInfo {
                videoPreviewCard(info)
            }

            // Error
            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(14)
    }

    // MARK: - Video Preview Card

    private func videoPreviewCard(_ info: (title: String, duration: String?, thumbnail: String?)) -> some View {
        HStack(spacing: 12) {
            // Thumbnail placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.red.opacity(0.15), .red.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 45)

                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.red.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(info.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let dur = info.duration {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text(dur)
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(.secondary)
                    }

                    Text(selectedQuality.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.quaternary.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.red.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Downloads List

    private var downloadsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            if youtubeService.downloads.isEmpty {
                emptyState
            } else {
                // Header
                HStack {
                    Text("Downloads")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    if youtubeService.downloads.contains(where: { $0.status == .complete || $0.status == .failed }) {
                        Button("Clear Finished") {
                            youtubeService.clearCompleted()
                        }
                        .font(.system(size: 11))
                        .buttonStyle(.plain)
                        .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 6)

                List(youtubeService.downloads) { dl in
                    downloadRow(dl)
                        .contextMenu {
                            if dl.status == .complete, let file = dl.localFile {
                                Button("Play") { onPlay(file) }
                                Button("Show in Finder") {
                                    NSWorkspace.shared.selectFile(
                                        file.path,
                                        inFileViewerRootedAtPath: file.deletingLastPathComponent().path
                                    )
                                }
                                Divider()
                            }
                            Button("Remove", role: .destructive) {
                                youtubeService.removeDownload(id: dl.id)
                            }
                        }
                }
                .listStyle(.inset)
            }
        }
    }

    // MARK: - Download Row

    private func downloadRow(_ dl: YouTubeService.YouTubeDownload) -> some View {
        HStack(spacing: 10) {
            // Status icon
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(statusColor(dl.status).opacity(0.1))
                    .frame(width: 28, height: 28)

                switch dl.status {
                case .queued:
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                case .fetching:
                    ProgressView()
                        .controlSize(.mini)
                case .downloading:
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(.blue)
                case .complete:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.green)
                case .failed:
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(dl.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                if dl.status == .downloading {
                    ProgressView(value: dl.progress, total: 100)
                        .tint(.red)

                    Text(String(format: "%.1f%%", dl.progress))
                        .font(.system(size: 10).monospacedDigit())
                        .foregroundStyle(.secondary)
                } else if dl.status == .failed, let err = dl.error {
                    Text(err)
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                        .lineLimit(2)
                } else if dl.status == .complete {
                    Text("Ready to play")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                } else if dl.status == .fetching {
                    Text("Fetching video info...")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if dl.status == .complete, let file = dl.localFile {
                Button {
                    onPlay(file)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Play")
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if dl.status == .complete, let file = dl.localFile {
                onPlay(file)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.red.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 36, weight: .ultraLight))
                    .foregroundStyle(.red.opacity(0.4))
            }

            VStack(spacing: 6) {
                Text("No YouTube downloads")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                Text("Paste a YouTube URL above to download and play")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            if !YouTubeService.isAvailable {
                VStack(spacing: 4) {
                    Text("yt-dlp required")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.orange)
                    Text("brew install yt-dlp")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func previewVideo() {
        guard YouTubeService.isYouTubeURL(urlString) else {
            errorMessage = "Not a valid YouTube URL"
            return
        }
        errorMessage = nil
        isPreviewing = true

        Task {
            if let info = await youtubeService.fetchInfo(urlString: urlString) {
                videoInfo = info
            } else {
                errorMessage = "Could not fetch video info"
            }
            isPreviewing = false
        }
    }

    private func startDownload() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard YouTubeService.isYouTubeURL(trimmed) else {
            errorMessage = "Not a valid YouTube URL. Supported: youtube.com, youtu.be"
            return
        }

        errorMessage = nil
        youtubeService.download(urlString: trimmed, quality: selectedQuality)
        urlString = ""
        videoInfo = nil
    }

    private func statusColor(_ status: YouTubeService.YouTubeDownload.Status) -> Color {
        switch status {
        case .queued: return .secondary
        case .fetching: return .blue
        case .downloading: return .blue
        case .complete: return .green
        case .failed: return .red
        }
    }
}
