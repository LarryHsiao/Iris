import SwiftUI

struct LyricBarView: View {
    let store: MonitorStore
    let settings: Settings

    static let bannerHeight: CGFloat = 14
    static let bannerSpacing: CGFloat = 2
    static var bannerTotalHeight: CGFloat { bannerHeight + bannerSpacing }

    var body: some View {
        VStack(spacing: LyricBarView.bannerSpacing) {
            HStack(spacing: 0) {
                callChip
                    .opacity(settings.showCall && store.callInCall ? 1 : 0)
                Spacer(minLength: 0)
            }
            .frame(height: LyricBarView.bannerHeight)
            .padding(.leading, 8)
            bar
        }
    }

    private var bar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                if settings.showArtwork && store.hasTrack {
                    Button(action: { store.playPause() }) {
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
                    .buttonStyle(.plain)
                }
                if settings.showLyrics {
                    Text(store.currentLine)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.leading, 8)
            Spacer(minLength: 12)
            HStack(spacing: 8) {
                ForEach(settings.tileOrder) { tile in
                    if settings.isVisible(tile) {
                        tileView(for: tile)
                    }
                }
            }
            .padding(.trailing, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.45))
        )
        .overlay(alignment: .bottom) {
            if settings.showProgress && store.isPlaying {
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

    @ViewBuilder
    private func tileView(for tile: Tile) -> some View {
        switch tile {
        case .network: networkTile
        case .cpu: RingGauge(
            percent: store.cpuPercent,
            label: "CPU",
            tint: Color(red: 0.38, green: 0.78, blue: 1.0)
        )
        case .gpu: RingGauge(
            percent: store.gpuPercent,
            label: "GPU",
            tint: Color(red: 0.75, green: 0.55, blue: 1.0)
        )
        case .mem: RingGauge(
            percent: store.memPercent,
            label: "MEM",
            tint: Color(red: 1.0, green: 0.72, blue: 0.30)
        )
        case .disk: diskTile
        case .battery: if store.batteryPresent {
            BatteryTile(percent: store.batteryPercent, charging: store.batteryCharging)
        }
        }
    }

    private var callChip: some View {
        HStack(spacing: 3) {
            Image(systemName: "phone.fill")
                .font(.system(size: 7, weight: .bold))
            Text(store.callAppName ?? "On call")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule().fill(Color(red: 0.93, green: 0.25, blue: 0.32).opacity(0.9))
        )
    }

    private var networkTile: some View {
        VStack(alignment: .trailing, spacing: 1) {
            HStack(spacing: 2) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Text(NetworkMonitor.format(bytesPerSec: store.netRxBytesPerSec))
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            HStack(spacing: 2) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Text(NetworkMonitor.format(bytesPerSec: store.netTxBytesPerSec))
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }

    private var diskTile: some View {
        HStack(spacing: 6) {
            ForEach(store.disks) { volume in
                DiskDotsGauge(volume: volume, showLabel: store.disks.count > 1)
            }
        }
    }
}
