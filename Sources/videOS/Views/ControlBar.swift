import SwiftUI

struct ControlBar: View {
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Seek bar at full width above controls
            SeekBar(
                position: Binding(
                    get: { viewModel.engine.position },
                    set: { _ in }
                ),
                duration: viewModel.engine.duration,
                currentTime: viewModel.engine.currentTime,
                isSeekable: viewModel.engine.isSeekable,
                bufferedPosition: viewModel.engine.bufferingProgress > 0
                    ? viewModel.engine.bufferingProgress / 100.0
                    : nil,
                onSeek: { pos in viewModel.seek(to: pos) }
            )
            .padding(.horizontal, 4)

            // Controls row
            HStack(spacing: 0) {
                // Left: time display + speed
                leftControls
                    .frame(minWidth: 120, alignment: .leading)

                Spacer()

                // Center: transport controls
                transportControls

                Spacer()

                // Right: track pickers, volume, fullscreen
                rightControls
                    .frame(minWidth: 120, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .padding(.top, 2)
        }
        .glassPanel(cornerRadius: 14)
    }

    // MARK: - Left Controls

    private var leftControls: some View {
        HStack(spacing: 6) {
            Text(TimeFormatter.format(milliseconds: viewModel.engine.currentTime))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.9))

            Text("/")
                .foregroundStyle(.white.opacity(0.4))

            Text(TimeFormatter.format(milliseconds: viewModel.engine.duration))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.5))

            SpeedBadge(speed: viewModel.playbackSpeed)
        }
        .font(.system(size: 12))
    }

    // MARK: - Transport Controls

    private var transportControls: some View {
        HStack(spacing: 16) {
            // Previous track
            Button {
                viewModel.handleKeyAction(.previousTrack)
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Previous (Cmd+P)")

            // Seek backward
            Button {
                viewModel.seekRelative(seconds: -10)
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Back 10s")

            // Play/Pause (larger, prominent)
            Button {
                viewModel.togglePlay()
            } label: {
                Image(systemName: viewModel.engine.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .animation(.easeInOut(duration: 0.15), value: viewModel.engine.isPlaying)
            }
            .buttonStyle(.plain)
            .help(viewModel.engine.isPlaying ? "Pause (Space)" : "Play (Space)")

            // Seek forward
            Button {
                viewModel.seekRelative(seconds: 10)
            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Forward 10s")

            // Next track
            Button {
                viewModel.handleKeyAction(.nextTrack)
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Next (Cmd+N)")
        }
    }

    // MARK: - Right Controls

    private var rightControls: some View {
        HStack(spacing: 8) {
            if !viewModel.engine.subtitleTracks.isEmpty {
                SubtitleTrackPicker(
                    tracks: viewModel.engine.subtitleTracks,
                    selectedTrack: Binding(
                        get: { viewModel.engine.currentSubtitleTrack },
                        set: { _ in }
                    ),
                    onSelect: { viewModel.engine.setSubtitleTrack($0) }
                )
            }

            if !viewModel.engine.audioTracks.isEmpty {
                AudioTrackPicker(
                    tracks: viewModel.engine.audioTracks,
                    selectedTrack: Binding(
                        get: { viewModel.engine.currentAudioTrack },
                        set: { _ in }
                    ),
                    onSelect: { viewModel.engine.setAudioTrack($0) }
                )
            }

            // Subtle separator
            if !viewModel.engine.subtitleTracks.isEmpty || !viewModel.engine.audioTracks.isEmpty {
                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 1, height: 16)
                    .padding(.horizontal, 2)
            }

            VolumeSlider(
                volume: Binding(
                    get: { viewModel.engine.volume },
                    set: { viewModel.setVolume($0) }
                ),
                isMuted: Binding(
                    get: { viewModel.engine.isMuted },
                    set: { _ in }
                ),
                onToggleMute: { viewModel.toggleMute() }
            )

            // Separator
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(width: 1, height: 16)
                .padding(.horizontal, 2)

            Button {
                viewModel.toggleFullscreen()
            } label: {
                Image(systemName: viewModel.isFullscreen
                      ? "arrow.down.right.and.arrow.up.left"
                      : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(viewModel.isFullscreen ? "Exit Fullscreen" : "Fullscreen (Cmd+F)")
        }
    }
}
