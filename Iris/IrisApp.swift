import SwiftUI
import UserNotifications

@main
struct IrisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        SwiftUI.Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var overlay: OverlayWindow?
    private var menuBar: MenuBarController?
    private var settingsWindow: SettingsWindow?
    private let store = MonitorStore()
    private let settings = Settings.shared
    private let cpu = CPUMonitor()
    private let net = NetworkMonitor()
    private let audio = AudioCapture()
    private let weather = WeatherMonitor()
    private let airQuality = AirQualityMonitor()
    private let fullscreen = FullscreenMonitor()
    private let wifi = WiFiInfoMonitor()
    private let calendar = CalendarMonitor()
    private var calendarTimer: Timer?
    private var timerCPU: Timer?
    private var timerTrack: Timer?
    private var timerWeather: Timer?
    private var timerAir: Timer?
    private var currentTrackID: String?
    private var lyrics: SyncedLyrics?
    private var didCheckNotificationStatus = false
    private var missingTrackTicks = 0
    private var isTickingTrack = false
    private static let missingTrackThreshold = 3

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
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
            self.syncAudioCapture()
            self.syncSpectrumLayout()
            self.applyOverlayVisibility()
            self.syncWiFiInfo()
            self.syncFocusSettings()
            self.syncCalendar()
            self.syncAirQuality()
        }

        fullscreen.onChange = { [weak self] _ in
            self?.applyOverlayVisibility()
        }
        fullscreen.start()

        wifi.onUpdate = { [weak self] ssid, ip in
            self?.store.wifiSSID = ssid
            self?.store.publicIP = ip
        }
        syncWiFiInfo()
        syncFocusSettings()
        syncCalendar()
        verifyNotificationAuthorizationIfNeeded()

        audio.onBands = { [weak self] bands in
            self?.store.spectrum = bands
        }
        audio.onStatus = { status in
            if case .permissionDenied = status {
                DispatchQueue.main.async { AppDelegate.presentPermissionAlert() }
            }
        }

        startTimers()
        syncAudioCapture()
        syncSpectrumLayout()
        syncAirQuality()
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
        Task { @MainActor in await self.tickWeather() }
        timerWeather = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.tickWeather() }
        }
    }

    private func tickWeather() async {
        let sample = await weather.sample()
        store.weather = sample
    }

    private func tickAirQuality() async {
        let sample = await airQuality.sample()
        store.airQuality = sample
    }

    private func syncAirQuality() {
        let needed = settings.showAir || settings.showWeather
        timerAir?.invalidate()
        timerAir = nil
        guard needed else {
            store.airQuality = nil
            return
        }
        Task { @MainActor in await tickAirQuality() }
        timerAir = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.tickAirQuality() }
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
            self.store.disks = DiskMonitor.sample(
                enabledExternalIDs: self.settings.enabledExternalDiskIDs
            )
            self.store.gpuPercent = GPUMonitor.sample()
            let net = self.net.sample()
            self.store.netRxBytesPerSec = net.rxBytesPerSec
            self.store.netTxBytesPerSec = net.txBytesPerSec
            let battery = BatteryMonitor.sample()
            self.store.batteryPercent = battery.percent
            self.store.batteryCharging = battery.isCharging
            self.store.batteryPresent = battery.isPresent
            self.store.recordSystemSample()
            Task.detached(priority: .utility) {
                let call = CallMonitor.sample()
                await MainActor.run {
                    self.store.callInCall = call.inCall
                    self.store.callAppName = call.appName
                    self.store.callAppProcessName = call.processName
                }
            }
            Task.detached(priority: .utility) {
                let claude = ClaudeMonitor.sample()
                await MainActor.run {
                    self.store.claudeState = claude
                }
            }
        }
    }

    private func restartSystemTimer() {
        scheduleSystemTimer()
    }

    private func syncAudioCapture() {
        if settings.showSpectrum {
            Task { await audio.start() }
        } else {
            Task { await audio.stop() }
        }
    }

    private func syncWiFiInfo() {
        if settings.showWiFiInfo {
            wifi.start()
        } else {
            wifi.stop()
        }
    }

    private func syncCalendar() {
        calendarTimer?.invalidate()
        calendarTimer = nil
        guard settings.showCalendar else {
            store.calendarEvent = nil
            store.calendarFollowUp = nil
            return
        }
        Task { @MainActor in
            await calendar.requestAccessIfNeeded()
            tickCalendar()
        }
        calendarTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickCalendar() }
        }
    }

    private func tickCalendar() {
        store.now = Date()
        let (current, followUp) = calendar.upcomingEvents()
        store.calendarEvent = current
        store.calendarFollowUp = followUp
    }

    private func syncFocusSettings() {
        store.focus.applyDurations(
            focus: settings.focusMinutes * 60,
            rest: settings.restMinutes * 60
        )
        store.focus.notificationsEnabled = settings.focusNotifications
        store.focus.soundEnabled = settings.focusSoundEnabled
        store.focus.soundName = settings.focusSoundName
        store.focus.soundRepeatCount = settings.focusSoundRepeatCount
        store.focus.soundRepeatInterval = settings.focusSoundRepeatInterval
        store.focus.pauseBetweenPhases = settings.focusPauseBetweenPhases
        verifyNotificationAuthorizationIfNeeded()
    }

    private func verifyNotificationAuthorizationIfNeeded() {
        guard !didCheckNotificationStatus, settings.focusNotifications else { return }
        didCheckNotificationStatus = true
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .denied else { return }
            DispatchQueue.main.async { AppDelegate.presentNotificationDeniedAlert() }
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    static func presentNotificationDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "Notifications are turned off for Iris"
        alert.informativeText = """
            Focus phase alerts won't appear until you enable notifications for Iris.
            Open System Settings → Notifications → Iris and allow Banners or Alerts.
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }

    private func applyOverlayVisibility() {
        guard let overlay else { return }
        let shouldHide = settings.autoHideOnFullscreen && fullscreen.isFullscreen
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            overlay.animator().alphaValue = shouldHide ? 0 : 1
        }
    }

    private func syncSpectrumLayout() {
        let show = settings.showSpectrum
        let spectrumTop = show && settings.spectrumPosition == .above
        let top: CGFloat = spectrumTop
            ? LyricBarView.spectrumStripHeight + LyricBarView.bannerSpacing
            : LyricBarView.bannerTotalHeight
        let bottom: CGFloat = (show && settings.spectrumPosition == .below)
            ? LyricBarView.spectrumStripTotalHeight
            : 0
        overlay?.setLayout(topExtra: top, bottomExtra: bottom)
    }

    static func presentPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording permission needed"
        alert.informativeText = """
            Iris uses Screen Recording to read the system audio stream for the spectrum visualizer.
            Grant access in System Settings → Privacy & Security → Screen Recording, then quit and reopen Iris.
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    private func tickTrack() async {
        guard !isTickingTrack else { return }
        isTickingTrack = true
        defer { isTickingTrack = false }
        let track = await Task.detached { SpotifyClient.currentTrack() }.value
        guard let track else {
            missingTrackTicks += 1
            if missingTrackTicks >= Self.missingTrackThreshold {
                store.currentLine = "—"
                store.hasTrack = false
                store.isPlaying = false
                store.artworkURL = nil
                store.progress = 0
                currentTrackID = nil
                lyrics = nil
            }
            return
        }
        missingTrackTicks = 0
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
