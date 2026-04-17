import SwiftUI

struct TrackPicker<Track: Identifiable & Hashable>: View {
    let title: String
    let icon: String
    let tracks: [Track]
    @Binding var selectedID: Int
    let trackName: (Track) -> String
    let trackID: (Track) -> Int

    var body: some View {
        Menu {
            ForEach(tracks) { track in
                Button {
                    selectedID = trackID(track)
                } label: {
                    HStack {
                        if selectedID == trackID(track) {
                            Image(systemName: "checkmark")
                        }
                        Text(trackName(track))
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                if !tracks.isEmpty {
                    Text("\(tracks.count)")
                        .font(.caption2)
                }
            }
            .foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

struct AudioTrackPicker: View {
    let tracks: [AudioTrack]
    @Binding var selectedTrack: Int
    var onSelect: (Int) -> Void

    var body: some View {
        TrackPicker(
            title: "Audio",
            icon: "waveform",
            tracks: tracks,
            selectedID: Binding(
                get: { selectedTrack },
                set: { id in
                    selectedTrack = id
                    onSelect(id)
                }
            ),
            trackName: \.name,
            trackID: \.id
        )
    }
}

struct SubtitleTrackPicker: View {
    let tracks: [SubtitleTrack]
    @Binding var selectedTrack: Int
    var onSelect: (Int) -> Void

    var body: some View {
        TrackPicker(
            title: "Subtitles",
            icon: "captions.bubble",
            tracks: tracks,
            selectedID: Binding(
                get: { selectedTrack },
                set: { id in
                    selectedTrack = id
                    onSelect(id)
                }
            ),
            trackName: \.name,
            trackID: \.id
        )
    }
}
