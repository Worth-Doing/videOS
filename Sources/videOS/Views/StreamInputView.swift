import SwiftUI
import AppKit

struct StreamInputView: View {
    @ObservedObject var streamService: StreamService
    var onOpen: (URL) -> Void

    @State private var urlString = ""
    @State private var errorMessage: String?
    @State private var isTesting = false

    var body: some View {
        VStack(spacing: 0) {
            inputSection
            Divider()

            if streamService.recentStreams.isEmpty {
                emptyState
            } else {
                recentList
            }
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
                Text("Open Network Stream")
                    .font(.system(size: 15, weight: .semibold))
            }

            // URL input field (larger, more prominent)
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                TextField("Enter stream URL...", text: $urlString)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .onSubmit { openStream() }

                if !urlString.isEmpty {
                    Button {
                        urlString = ""
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
                    .strokeBorder(errorMessage != nil ? .red.opacity(0.5) : .clear, lineWidth: 1)
            )

            // Protocol hint chips
            HStack(spacing: 8) {
                Text("Protocols:")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)

                ForEach(["http://", "https://", "rtsp://", "rtp://"], id: \.self) { proto in
                    Button {
                        urlString = proto
                    } label: {
                        Text(proto.replacingOccurrences(of: "://", with: "").uppercased())
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if isTesting {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Connecting...")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    openStream()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                        Text("Open")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(urlString.trimmingCharacters(in: .whitespaces).isEmpty)
            }

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

    // MARK: - Recent Streams

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent Streams")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Button {
                    streamService.clearAll()
                } label: {
                    Text("Clear All")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            List(streamService.recentStreams) { stream in
                HStack(spacing: 10) {
                    // Protocol icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(.blue.opacity(0.1))
                            .frame(width: 28, height: 28)
                        Image(systemName: protocolIcon(for: stream.url))
                            .font(.system(size: 12))
                            .foregroundStyle(.blue.opacity(0.7))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stream.title)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text(stream.url.absoluteString)
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)

                            Text("\u{00B7}")
                                .foregroundStyle(.quaternary)

                            Text(relativeTimeString(from: stream.lastUsed))
                                .font(.system(size: 10))
                                .foregroundStyle(.quaternary)
                        }
                    }

                    Spacer()

                    Button {
                        onOpen(stream.url)
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 3)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    onOpen(stream.url)
                }
                .contextMenu {
                    Button("Open") { onOpen(stream.url) }
                    Button("Copy URL") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(stream.url.absoluteString, forType: .string)
                    }
                    Divider()
                    Button("Remove", role: .destructive) {
                        streamService.removeStream(id: stream.id)
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))

            StatusBar(
                itemCount: streamService.recentStreams.count,
                additionalInfo: "recent streams"
            )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.quaternary)
                    .frame(width: 72, height: 72)
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                Text("No recent streams")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                Text("Supports HTTP, RTSP, HLS, RTP, and more")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func openStream() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = streamService.validate(urlString: trimmed) else {
            errorMessage = "Invalid URL. Use http://, https://, rtsp://, or rtp://"
            return
        }
        errorMessage = nil
        isTesting = true

        // Brief delay to show the connecting indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isTesting = false
            streamService.addToRecent(url: url)
            onOpen(url)
            urlString = ""
        }
    }

    private func protocolIcon(for url: URL) -> String {
        switch url.scheme?.lowercased() {
        case "rtsp", "rtp":
            return "video.fill"
        case "http", "https":
            return "globe"
        default:
            return "antenna.radiowaves.left.and.right"
        }
    }

    private func relativeTimeString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        if interval < 172800 { return "Yesterday" }
        if interval < 604800 { return "\(Int(interval / 86400))d ago" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
