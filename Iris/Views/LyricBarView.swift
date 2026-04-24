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
            topSection
            bar
            bottomSection
        }
    }

    @ViewBuilder
    private var topSection: some View {
        if settings.showSpectrum && settings.spectrumPosition == .above {
            TimelineView(.periodic(from: .now, by: 0.2)) { context in
                topSpectrumStrip(active: spectrumActive(at: context.date))
            }
        } else {
            plainBannerStrip
        }
    }

    @ViewBuilder
    private func topSpectrumStrip(active: Bool) -> some View {
        ZStack(alignment: .bottomLeading) {
            if active {
                SpectrumView(bands: store.spectrum, lastActive: store.spectrumLastActiveAt)
                    .padding(.horizontal, 8)
            }
            bannerChips
                .padding(.leading, active ? 12 : 8)
                .padding(.bottom, active ? 4 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .bottomLeading)
        .frame(height: LyricBarView.spectrumStripHeight)
        .padding(.bottom, LyricBarView.bannerSpacing)
    }

    @ViewBuilder
    private var plainBannerStrip: some View {
        HStack(spacing: 0) {
            bannerChips
            Spacer(minLength: 0)
        }
        .frame(height: LyricBarView.bannerHeight)
        .padding(.leading, 8)
        .padding(.bottom, LyricBarView.bannerSpacing)
    }

    @ViewBuilder
    private var bottomSection: some View {
        if settings.showSpectrum && settings.spectrumPosition == .below {
            TimelineView(.periodic(from: .now, by: 0.2)) { context in
                if spectrumActive(at: context.date) {
                    SpectrumView(bands: store.spectrum, flipped: true, lastActive: store.spectrumLastActiveAt)
                        .frame(height: LyricBarView.spectrumStripHeight)
                        .padding(.horizontal, 8)
                        .padding(.top, LyricBarView.spectrumStripSpacing)
                } else {
                    Color.clear
                        .frame(height: LyricBarView.spectrumStripTotalHeight)
                }
            }
        }
    }

    private func spectrumActive(at date: Date) -> Bool {
        let idle = date.timeIntervalSince(store.spectrumLastActiveAt)
        return idle <= SpectrumView.idleThreshold + SpectrumView.fadeDuration
    }

    private var bar: some View {
        HStack(spacing: 0) {
            leadingBlock
                .padding(.leading, 8)
                .animation(.easeInOut(duration: 0.18), value: store.expandedTile)
            Spacer(minLength: 8)
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
    private var leadingBlock: some View {
        if !store.hasTrack && settings.showCalendar {
            IdleView(event: store.calendarEvent, now: store.now)
        } else {
            HStack(spacing: 6) {
                if settings.showArtwork {
                    artworkButton
                }
                if let expanded = store.expandedTile, LyricBarView.expandable(expanded) {
                    expandedRow(tile: expanded)
                } else if settings.showLyrics {
                    Text(store.hasTrack ? store.currentLine : "Standing by")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(store.hasTrack ? .white : .white.opacity(0.55))
                        .lineLimit(settings.thinMode ? 1 : 2)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }

    private var artworkButton: some View {
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

    @ViewBuilder
    private var bannerChips: some View {
        HStack(spacing: 4) {
            if settings.showCall && store.callInCall {
                callChip
            }
            if shouldShowCalendarBanner, let event = store.calendarEvent {
                calendarChip(event: event)
            }
        }
    }

    private var shouldShowCalendarBanner: Bool {
        guard settings.showCalendar, let event = store.calendarEvent else { return false }
        if event.isOngoing { return false }
        let minutesUntilStart = event.start.timeIntervalSince(store.now) / 60
        return minutesUntilStart > 0 && minutesUntilStart <= settings.calendarImminentMinutes
    }

    @ViewBuilder
    private func tileView(for tile: Tile) -> some View {
        if tile == .calendar {
            calendarTileButton
        } else if LyricBarView.expandable(tile) {
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
    private var calendarTileButton: some View {
        if store.hasTrack, let event = store.calendarEvent {
            Button(action: { toggleExpansion(for: .calendar) }) {
                CalendarTile(event: event, now: store.now, showLabel: !settings.thinMode)
                    .opacity(store.expandedTile == .calendar ? 0.55 : 1)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func expandedRow(tile: Tile) -> some View {
        switch tile {
        case .calendar:
            if let event = store.calendarEvent {
                calendarExpandedRow(event: event)
            }
        case .disk:
            diskExpandedRow
        default:
            expandedSparklineRow(tile: tile)
        }
    }

    private var diskExpandedRow: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(store.disks) { volume in
                Text("\(volume.name) · \(Self.byteFormatter.string(fromByteCount: volume.freeBytes)) free of \(Self.byteFormatter.string(fromByteCount: volume.totalBytes))")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }
        }
    }

    private static let byteFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        f.allowedUnits = [.useGB, .useTB, .useMB]
        return f
    }()

    private func calendarExpandedRow(event: CalendarEventSample) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(event.title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(calendarSubtitle(for: event))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)
        }
    }

    private func calendarSubtitle(for event: CalendarEventSample) -> String {
        let start = Self.timeFormatter.string(from: event.start)
        let end = Self.timeFormatter.string(from: event.end)
        if event.isOngoing {
            let minutesLeft = max(0, Int(event.end.timeIntervalSince(store.now) / 60))
            return "ends in \(minutesLeft)m · \(end)"
        }
        let minutesUntil = Int(event.start.timeIntervalSince(store.now) / 60)
        let relative = minutesUntil <= 0 ? "now" : "in \(minutesUntil)m"
        return "\(relative) · \(start) – \(end)"
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
            tint: Color(red: 0.38, green: 0.78, blue: 1.0),
            showLabel: !settings.thinMode
        )
        case .gpu: RingGauge(
            percent: store.gpuPercent,
            label: "GPU",
            tint: Color(red: 0.75, green: 0.55, blue: 1.0),
            showLabel: !settings.thinMode
        )
        case .mem: RingGauge(
            percent: store.memPercent,
            label: "MEM",
            tint: Color(red: 1.0, green: 0.72, blue: 0.30),
            showLabel: !settings.thinMode
        )
        case .disk: diskTile
        case .battery: if store.batteryPresent {
            BatteryTile(
                percent: store.batteryPercent,
                charging: store.batteryCharging,
                showLabel: !settings.thinMode
            )
        }
        case .weather: WeatherTile(sample: store.weather)
        case .focus: FocusTile(timer: store.focus, showLabel: !settings.thinMode)
        case .calendar: EmptyView()
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

    private static func expandable(_ tile: Tile) -> Bool {
        switch tile {
        case .cpu, .gpu, .mem, .network, .calendar, .disk: return true
        case .battery, .weather, .focus: return false
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

    private func calendarChip(event: CalendarEventSample) -> some View {
        let minutesUntil = max(0, Int(event.start.timeIntervalSince(store.now) / 60))
        let label = minutesUntil <= 0 ? "now" : "\(minutesUntil)m"
        return HStack(spacing: 3) {
            Image(systemName: "calendar")
                .font(.system(size: 7, weight: .bold))
            Text("\(event.title) · \(label)")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule().fill(Color(red: 0.95, green: 0.60, blue: 0.20).opacity(0.9))
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
                DiskDotsGauge(volume: volume, showLabel: store.disks.count > 1 && !settings.thinMode)
            }
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("HH:mm")
        return f
    }()
}
