import SwiftUI

@main
struct IrisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlay: OverlayWindow?
    private var menuBar: MenuBarController?
    private let store = MonitorStore()
    private let cpu = CPUMonitor()
    private var timerCPU: Timer?
    private var timerTrack: Timer?
    private var currentTrackID: String?
    private var lyrics: SyncedLyrics?

    func applicationDidFinishLaunching(_ notification: Notification) {
        overlay = OverlayWindow(rootView: LyricBarView(store: store))
        overlay?.orderFrontRegardless()

        let bar = MenuBarController()
        bar.onToggle = { [weak self] in
            guard let win = self?.overlay else { return }
            if win.isVisible { win.orderOut(nil) } else { win.orderFrontRegardless() }
        }
        menuBar = bar

        startTimers()
    }

    private func startTimers() {
        timerCPU = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.store.cpuPercent = self.cpu.sample()
        }
        timerTrack = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.tickTrack() }
        }
    }

    private func tickTrack() async {
        let track = await Task.detached { SpotifyClient.currentTrack() }.value
        guard let track else {
            store.currentLine = "—"
            return
        }
        if track.id != currentTrackID {
            currentTrackID = track.id
            lyrics = await LyricsClient.fetch(track: track.name, artist: track.artist)
        }
        if let line = lyrics?.line(at: track.positionSeconds) {
            store.currentLine = line
        } else {
            store.currentLine = "\(track.artist) — \(track.name)"
        }
    }
}
