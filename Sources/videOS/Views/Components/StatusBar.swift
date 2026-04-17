import SwiftUI

struct StatusBar: View {
    let itemCount: Int
    let additionalInfo: String?

    init(itemCount: Int, additionalInfo: String? = nil) {
        self.itemCount = itemCount
        self.additionalInfo = additionalInfo
    }

    var body: some View {
        HStack {
            Text("\(itemCount) items")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let info = additionalInfo {
                Text("\u{00B7}")
                    .foregroundStyle(.tertiary)
                Text(info)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassToolbar()
    }
}
