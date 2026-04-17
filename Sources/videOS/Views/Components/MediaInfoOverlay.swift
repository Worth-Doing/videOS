import SwiftUI

struct MediaInfoOverlay: View {
    let title: String
    let details: [(String, String)]
    var onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.blue)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isVisible = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        onDismiss()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()
                .opacity(0.5)

            ForEach(Array(details.enumerated()), id: \.offset) { _, detail in
                HStack(alignment: .top) {
                    Text(detail.0)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .trailing)

                    Text(detail.1)
                        .font(.system(size: 11))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
        .frame(width: 260)
        .glassPanel(cornerRadius: 10)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}
