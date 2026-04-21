import SwiftUI

@main
struct IrisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        SwiftUI.Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlay: OverlayWindow?
    private var menuBar: MenuBarController?
    private var settingsWindow: SettingsWindow?
    private let store = MonitorStore()
    private let settings = Settings.shared
    private let cpu = CPUMonitor()
    private let net = NetworkMonitor()
    private var timerCPU: Timer?
    private var timerTrack: Timer?
    private var currentTrackID: String?
    private var lyrics: SyncedLyrics?

    func applicationDidFinishLaunching(_ notification: Notification) {
        overlay = OverlayWindow(
            rootView: LyricBarView(store: store, settings: settings),
            width: settings.overlayWidth
        )
        overlay?.orderFrontRegardless()

        let bar = MenuBarController()
        bar.onToggle = { [weak self] in
            guard let win = self?.overlay else { return }
            if win.isVisible { win.orderOut(nil) } else { win.orderFrontRegardless() }
        }
        bar.onOpenSettings = { [weak self] in self?.openSettings() }
        menuBar = bar

        settings.onApplied = { [weak self] in
            guard let self else { return }
            self.restartSystemTimer()
            self.overlay?.setWidth(self.settings.overlayWidth)
        }

        startTimers()
    }

    private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindow(
                settings: settings,
                demoStore: MonitorStore.demo(),
                onResetPosition: { [weak self] in self?.overlay?.resetPosition() }
            )
        }
        settingsWindow?.show()
    }

    private func startTimers() {
        scheduleSystemTimer()
        timerTrack = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.tickTrack() }
        }
    }

    private func scheduleSystemTimer() {
        timerCPU?.invalidate()
        timerCPU = Timer.scheduledTimer(
            withTimeInterval: settings.samplingInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self else { return }
            self.store.cpuPercent = self.cpu.sample()
            self.store.memPercent = MemoryMonitor.sample()
            self.store.diskFreeBytes = DiskMonitor.freeBytes()
            self.store.gpuPercent = GPUMonitor.sample()
            let net = self.net.sample()
            self.store.netRxBytesPerSec = net.rxBytesPerSec
            self.store.netTxBytesPerSec = net.txBytesPerSec
            let battery = BatteryMonitor.sample()
            self.store.batteryPercent = battery.percent
            self.store.batteryCharging = battery.isCharging
            self.store.batteryPresent = battery.isPresent
        }
    }

    private func restartSystemTimer() {
        scheduleSystemTimer()
    }

    private func tickTrack() async {
        let track = await Task.detached { SpotifyClient.currentTrack() }.value
        guard let track else {
            store.currentLine = "—"
            store.hasTrack = false
            store.isPlaying = false
            store.artworkURL = nil
            store.progress = 0
            return
        }
        store.hasTrack = true
        store.isPlaying = track.isPlaying
        store.progress = track.durationSeconds > 0
            ? min(max(track.positionSeconds / track.durationSeconds, 0), 1)
            : 0
        if track.id != currentTrackID {
            currentTrackID = track.id
            store.artworkURL = track.artworkURL.flatMap(URL.init(string:))
            lyrics = await LyricsClient.fetch(track: track.name, artist: track.artist)
        }
        if let line = lyrics?.line(at: track.positionSeconds) {
            store.currentLine = line
        } else {
            store.currentLine = "\(track.artist) — \(track.name)"
        }
    }
}
