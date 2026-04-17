import SwiftUI

struct ThumbnailPreview: View {
    let time: Int64
    let position: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.7))
                .frame(width: 120, height: 68)
                .overlay(
                    Image(systemName: "film")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                )

            Text(TimeFormatter.format(milliseconds: time))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .offset(x: position)
    }
}

struct SpeedBadge: View {
    let speed: Float

    var body: some View {
        if speed != 1.0 {
            Text(String(format: "%.2gx", speed))
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.orange.opacity(0.8))
                .clipShape(Capsule())
        }
    }
}
