import SwiftUI

struct LyricBarView: View {
    let store: MonitorStore

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                if store.isPlaying {
                    AsyncImage(url: store.artworkURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Image(systemName: "music.note")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.white.opacity(0.1))
                        }
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                Text(store.currentLine)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
            }
            .padding(.leading, 8)
            Spacer(minLength: 12)
            CPUChartView(samples: store.cpuHistory)
                .frame(width: 64, height: 24)
                .padding(.trailing, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.45))
        )
        .overlay(alignment: .bottom) {
            if store.isPlaying {
                GeometryReader { geo in
                    Capsule()
                        .fill(Color(red: 0.11, green: 0.84, blue: 0.38))
                        .frame(width: geo.size.width * store.progress, height: 2)
                        .animation(.linear(duration: 0.4), value: store.progress)
                }
                .frame(height: 2)
                .padding(.horizontal, 6)
                .padding(.bottom, 2)
            }
        }
    }
}
