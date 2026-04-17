import SwiftUI

struct VolumeSlider: View {
    @Binding var volume: Int
    @Binding var isMuted: Bool
    var onToggleMute: () -> Void

    @State private var isHovering = false
    @State private var showTooltip = false

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onToggleMute) {
                Image(systemName: volumeIcon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(isMuted ? "Unmute" : "Mute")

            if isHovering {
                HStack(spacing: 6) {
                    Slider(
                        value: Binding(
                            get: { Double(volume) },
                            set: { volume = Int($0) }
                        ),
                        in: 0...150,
                        step: 1
                    )
                    .frame(width: 80)
                    .tint(.white.opacity(0.8))

                    Text("\(volume)%")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)

                    Text("\u{2191}\u{2193}")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
            }
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isHovering = hovering
            }
        }
        .help(isHovering ? "" : "Volume: \(volume)%")
    }

    private var volumeIcon: String {
        if isMuted || volume == 0 { return "speaker.slash.fill" }
        if volume < 25 { return "speaker.fill" }
        if volume < 50 { return "speaker.wave.1.fill" }
        if volume < 80 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }
}
