import SwiftUI

struct SeekBar: View {
    @Binding var position: Float
    let duration: Int64
    let currentTime: Int64
    let isSeekable: Bool
    var bufferedPosition: Float?
    var onSeek: (Float) -> Void

    @State private var isDragging = false
    @State private var dragPosition: Float = 0
    @State private var isHovering = false
    @State private var hoverPosition: Float = 0

    private let trackHeight: CGFloat = 4
    private let trackHeightHover: CGFloat = 8
    private let thumbSize: CGFloat = 16

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let displayPosition = isDragging ? dragPosition : position
            let currentTrackHeight = (isHovering || isDragging) ? trackHeightHover : trackHeight

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: currentTrackHeight)

                // Buffered range indicator
                if let buffered = bufferedPosition, buffered > 0 {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: max(0, width * CGFloat(buffered)), height: currentTrackHeight)
                }

                // Progress fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, width * CGFloat(displayPosition)), height: currentTrackHeight)

                // Hover position preview line
                if isHovering && !isDragging {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 1.5, height: currentTrackHeight + 4)
                        .offset(x: max(0, min(width - 1, width * CGFloat(hoverPosition))))
                }

                // Thumb
                if isHovering || isDragging {
                    Circle()
                        .fill(.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                        .shadow(color: isDragging ? .blue.opacity(0.4) : .clear, radius: 6)
                        .scaleEffect(isDragging ? 1.15 : 1.0)
                        .offset(x: max(0, min(width - thumbSize, width * CGFloat(displayPosition) - thumbSize / 2)))
                        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isDragging)
                }

                // Hover time tooltip
                if isHovering || isDragging {
                    let tooltipPosition = isDragging ? dragPosition : hoverPosition
                    let timeMs = Int64(Float(duration) * tooltipPosition)
                    let tooltipX = max(30, min(width - 30, width * CGFloat(tooltipPosition)))

                    Text(TimeFormatter.format(milliseconds: timeMs))
                        .font(.caption2.monospacedDigit().bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(.black.opacity(0.75))
                        )
                        .offset(x: tooltipX - width / 2, y: -24)
                        .transition(.opacity)
                }
            }
            .frame(height: max(thumbSize, currentTrackHeight + 8))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isSeekable else { return }
                        isDragging = true
                        dragPosition = Float(max(0, min(1, value.location.x / width)))
                    }
                    .onEnded { value in
                        guard isSeekable else { return }
                        let finalPos = Float(max(0, min(1, value.location.x / width)))
                        onSeek(finalPos)
                        isDragging = false
                    }
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovering = hovering
                }
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoverPosition = Float(max(0, min(1, location.x / width)))
                case .ended:
                    break
                @unknown default:
                    break
                }
            }
        }
        .frame(height: thumbSize + 16)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }
}
