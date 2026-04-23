import SwiftUI

struct LyricBarView: View {
    let store: MonitorStore
    let settings: Settings

    static let bannerHeight: CGFloat = 14
    static let bannerSpacing: CGFloat = 4
    static var bannerTotalHeight: CGFloat { bannerHeight + bannerSpacing }
    static let spectrumStripHeight: CGFloat = 56 * 2 / 3
    static let spectrumStripSpacing: CGFloat = 2
    static var spectrumStripTotalHeight: CGFloat { spectrumStripHeight + spectrumStripSpacing }

    var body: some View {
        VStack(spacing: 0) {
            if settings.showSpectrum && settings.spectrumPosition == .above {
                ZStack(alignment: .bottomLeading) {
                    SpectrumView(bands: store.spectrum, lastActive: store.spectrumLastActiveAt)
                        .frame(height: LyricBarView.spectrumStripHeight)
                        .padding(.horizontal, 8)
                    callChip
                        .opacity(settings.showCall && store.callInCall ? 1 : 0)
                        .padding(.leading, 8)
                }
                .padding(.bottom, LyricBarView.bannerSpacing)
            } else {
                HStack(spacing: 0) {
                    callChip
                        .opacity(settings.showCall && store.callInCall ? 1 : 0)
                    Spacer(minLength: 0)
                }
                .frame(height: LyricBarView.bannerHeight)
                .padding(.leading, 8)
                .padding(.bottom, LyricBarView.bannerSpacing)
            }
            bar
            if settings.showSpectrum && settings.spectrumPosition == .below {
                SpectrumView(bands: store.spectrum, flipped: true, lastActive: store.spectrumLastActiveAt)
                    .frame(height: LyricBarView.spectrumStripHeight)
                    .padding(.horizontal, 8)
                    .padding(.top, LyricBarView.spectrumStripSpacing)
            }
        }
    }

    private var bar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                if settings.showArtwork {
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
                if let expanded = store.expandedTile,
                   LyricBarView.sparklineSupported(expanded) {
                    expandedSparklineRow(tile: expanded)
                } else if settings.showLyrics {
                    Text(store.hasTrack ? store.currentLine : "Standing by")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(store.hasTrack ? .white : .white.opacity(0.55))
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.leading, 8)
            .animation(.easeInOut(duration: 0.18), value: store.expandedTile)
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
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.45))
                if settings.showSpectrum && settings.spectrumPosition == .behind {
                    SpectrumView(bands: store.spectrum, lastActive: store.spectrumLastActiveAt)
                        .opacity(0.35)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .allowsHitTesting(false)
                }
            }
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
        if LyricBarView.sparklineSupported(tile) {
            Button(action: { toggleExpansion(for: tile) }) {
                baseTile(for: tile)
                    .opacity(store.expandedTile == tile ? 0.55 : 1)
            }
            .buttonStyle(.plain)
        } else {
            baseTile(for: tile)
        }
    }

    @ViewBuilder
    private func expandedSparklineRow(tile: Tile) -> some View {
        HStack(spacing: 8) {
            expandedLabelView(for: tile)
                .fixedSize(horizontal: true, vertical: false)
            sparklineView(for: tile)
                .frame(height: 24)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func expandedLabelView(for tile: Tile) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(expandedLabel(for: tile))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
            if tile == .network, settings.showWiFiInfo, let sub = wifiInfoLine {
                Text(sub)
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }

    private var wifiInfoLine: String? {
        let ssid = store.wifiSSID
        let ip = store.publicIP
        if ssid == nil && ip == nil { return nil }
        let ssidPart = ssid ?? "—"
        let ipPart = ip ?? "…"
        return "\(ssidPart) · \(ipPart)"
    }

    private func expandedLabel(for tile: Tile) -> String {
        switch tile {
        case .cpu: return "CPU \(Int(store.cpuPercent.rounded()))%"
        case .gpu: return "GPU \(Int(store.gpuPercent.rounded()))%"
        case .mem: return "MEM \(Int(store.memPercent.rounded()))%"
        case .network:
            let rx = NetworkMonitor.format(bytesPerSec: store.netRxBytesPerSec)
            let tx = NetworkMonitor.format(bytesPerSec: store.netTxBytesPerSec)
            return "NET ↓\(rx) ↑\(tx)"
        default: return ""
        }
    }

    @ViewBuilder
    private func baseTile(for tile: Tile) -> some View {
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
        case .weather: WeatherTile(sample: store.weather)
        case .focus: FocusTile(timer: store.focus)
        }
    }

    @ViewBuilder
    private func sparklineView(for tile: Tile) -> some View {
        switch tile {
        case .cpu:
            Sparkline(
                samples: store.cpuHistory,
                tint: Color(red: 0.38, green: 0.78, blue: 1.0),
                maxValue: 100
            )
        case .gpu:
            Sparkline(
                samples: store.gpuHistory,
                tint: Color(red: 0.75, green: 0.55, blue: 1.0),
                maxValue: 100
            )
        case .mem:
            Sparkline(
                samples: store.memHistory,
                tint: Color(red: 1.0, green: 0.72, blue: 0.30),
                maxValue: 100
            )
        case .network:
            networkSparkline
        default:
            EmptyView()
        }
    }

    private var networkSparkline: some View {
        let upper = max(store.netRxHistory.max() ?? 0, store.netTxHistory.max() ?? 0, 1)
        return ZStack {
            Sparkline(
                samples: store.netRxHistory,
                tint: Color(red: 0.38, green: 0.78, blue: 1.0),
                maxValue: upper
            )
            Sparkline(
                samples: store.netTxHistory,
                tint: Color(red: 1.0, green: 0.55, blue: 0.55),
                maxValue: upper
            )
        }
    }

    private static func sparklineSupported(_ tile: Tile) -> Bool {
        switch tile {
        case .cpu, .gpu, .mem, .network: return true
        case .disk, .battery, .weather, .focus: return false
        }
    }

    private func toggleExpansion(for tile: Tile) {
        if store.expandedTile == tile {
            store.expandedTile = nil
        } else {
            store.expandedTile = tile
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                if store.expandedTile == tile {
                    store.expandedTile = nil
                }
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
