import SwiftUI
import AppKit

struct SettingsView: View {
    @Bindable var live: Settings
    let demoStore: MonitorStore
    var onResetPosition: () -> Void
    var onClose: () -> Void
    var onApplyError: (Error) -> Void

    @State private var draft: Settings
    @State private var showClaudeHelp: Bool = false
    @State private var claudeHookStatus: ClaudeHookInstaller.Status = .notInstalled
    @State private var claudeHookBusy: Bool = false
    @State private var claudeHookManualOpen: Bool = false

    init(
        live: Settings,
        demoStore: MonitorStore,
        onResetPosition: @escaping () -> Void,
        onClose: @escaping () -> Void,
        onApplyError: @escaping (Error) -> Void
    ) {
        self.live = live
        self.demoStore = demoStore
        self.onResetPosition = onResetPosition
        self.onClose = onClose
        self.onApplyError = onApplyError
        _draft = State(initialValue: live.copy())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 14) {
                    preview
                    Divider()
                    TabView {
                        contentForm
                            .tabItem { Label("Content", systemImage: "text.alignleft") }
                        tilesForm
                            .tabItem { Label("Tiles", systemImage: "square.grid.2x2") }
                        systemForm
                            .tabItem { Label("System", systemImage: "gearshape") }
                    }
                    .frame(minHeight: 260)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                Spacer()
                Button("Close", role: .cancel) { onClose() }
                    .keyboardShortcut(.cancelAction)
                Button("Apply", action: apply)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 520, height: 560)
    }

    private var contentForm: some View {
        Form {
            Section("Left") {
                Toggle("Lyrics", isOn: $draft.showLyrics)
                Toggle("Album artwork", isOn: $draft.showArtwork)
                Toggle("Progress bar", isOn: $draft.showProgress)
            }
            Section("Call") {
                Toggle("Show on-call label", isOn: $draft.showCall)
            }
            Section("Claude") {
                HStack {
                    Toggle("Show Claude-thinking tile", isOn: $draft.showClaude)
                    Spacer()
                    Button {
                        showClaudeHelp = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Hook setup")
                    .popover(isPresented: $showClaudeHelp, arrowEdge: .trailing) {
                        claudeHookHelp
                    }
                }
                if draft.showClaude {
                    Text("A sparkle tile lights while any Claude Code session is mid-turn. Requires the iris-claude hooks — click ⓘ for setup.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Section("Weather") {
                Picker("Units", selection: $draft.weatherUnit) {
                    ForEach(WeatherUnit.allCases) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                Text("When no track is playing, a brief weather line fills the lyric slot.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Calendar") {
                Toggle("Show upcoming calendar event", isOn: $draft.showCalendar)
                if draft.showCalendar {
                    HStack {
                        Text("Imminent banner at")
                        Slider(value: $draft.calendarImminentMinutes, in: 1...30, step: 1)
                        Text("\(Int(draft.calendarImminentMinutes)) min")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 64, alignment: .trailing)
                    }
                    Text("Needs Calendar access (prompted on enable). Events shown: next event within the upcoming hour.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Section("Audio") {
                Toggle("Show spectrum visualizer", isOn: $draft.showSpectrum)
                Picker("Position", selection: $draft.spectrumPosition) {
                    ForEach(SpectrumPosition.allCases) { position in
                        Text(position.label).tag(position)
                    }
                }
                .disabled(!draft.showSpectrum)
                Text("Requires Screen Recording permission; enabling this will prompt on first use.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private static let claudeHookSnippet = """
"UserPromptSubmit": [{ "hooks": [{ "type":"command",
  "command":"~/.claude/hooks/iris-claude-on.sh" }] }],
"PreToolUse":  [{ "hooks": [{ "type":"command",
  "command":"~/.claude/hooks/iris-claude-on.sh" }] }],
"PostToolUse": [{ "hooks": [{ "type":"command",
  "command":"~/.claude/hooks/iris-claude-on.sh" }] }],
"Stop":        [{ "hooks": [{ "type":"command",
  "command":"~/.claude/hooks/iris-claude-off.sh" }] }]
"""

    private var claudeHookHelp: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Claude indicator setup")
                .font(.headline)
            Text("Iris polls `~/.claude/iris-status/`. Two hook scripts maintain that directory on each Claude Code turn boundary.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button(action: runClaudeHookInstall) {
                    if claudeHookBusy {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(claudeHookStatus == .installed ? "Reinstall hooks" : "Install hooks")
                    }
                }
                .disabled(claudeHookBusy)
                .keyboardShortcut(.defaultAction)
                Button("Change path…", action: pickClaudeHooksRoot)
                    .disabled(claudeHookBusy)
                claudeHookStatusBadge
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Root: \(claudeHooksRootDisplay)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("Installs two scripts into `<root>/hooks/` and patches `<root>/settings.json`. Existing hooks are preserved; safe to re-run. A timestamped backup of `settings.json` is written first.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 6) {
                Button {
                    claudeHookManualOpen.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: claudeHookManualOpen ? "chevron.down" : "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                        Text("Manual setup")
                            .font(.system(size: 11, weight: .semibold))
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if claudeHookManualOpen {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("If you'd rather wire it by hand, place the bundled scripts at `~/.claude/hooks/iris-claude-{on,off}.sh` and add this to `~/.claude/settings.json`:")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(Self.claudeHookSnippet)
                            .font(.system(size: 10, design: .monospaced))
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.06))
                            .cornerRadius(4)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 380)
        .onAppear {
            claudeHookStatus = ClaudeHookInstaller.currentStatus(rootRaw: draft.claudeHooksRoot)
        }
    }

    @ViewBuilder
    private var claudeHookStatusBadge: some View {
        switch claudeHookStatus {
        case .notInstalled:
            Label("Not installed", systemImage: "circle.dashed")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        case .installed:
            Label("Installed", systemImage: "checkmark.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.green)
        case .partial(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.orange)
        case .failed(let message):
            Label(message, systemImage: "xmark.octagon.fill")
                .font(.system(size: 11))
                .foregroundStyle(.red)
                .lineLimit(2)
        }
    }

    private func runClaudeHookInstall() {
        claudeHookBusy = true
        let rootRaw = draft.claudeHooksRoot
        Task.detached {
            let result = ClaudeHookInstaller.install(rootRaw: rootRaw)
            await MainActor.run {
                claudeHookStatus = result
                claudeHookBusy = false
                if result == .installed {
                    draft.showClaude = true
                }
            }
        }
    }

    private func pickClaudeHooksRoot() {
        let panel = NSOpenPanel()
        panel.title = "Choose Claude config root"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        let resolved = ClaudeHookInstaller.resolveRoot(draft.claudeHooksRoot)
        if FileManager.default.fileExists(atPath: resolved.path) {
            panel.directoryURL = resolved
        }
        if panel.runModal() == .OK, let url = panel.url {
            draft.claudeHooksRoot = ClaudeHookInstaller.displayPath(for: url)
            claudeHookStatus = ClaudeHookInstaller.currentStatus(rootRaw: draft.claudeHooksRoot)
        }
    }

    private var claudeHooksRootDisplay: String {
        let raw = draft.claudeHooksRoot
        if raw.isEmpty { return "~/.claude" }
        return raw
    }

    private var tilesForm: some View {
        Form {
            Section("Tiles") {
                ForEach(Array(draft.tileOrder.enumerated()), id: \.element) { index, tile in
                    tileRow(tile: tile, index: index)
                }
            }
            Section("Disks") {
                ForEach(detectedVolumes) { volume in
                    diskRow(volume)
                }
            }
            Section("Focus") {
                HStack {
                    Text("Focus")
                    Slider(value: $draft.focusMinutes, in: 5...90, step: 1)
                    Text("\(Int(draft.focusMinutes)) min")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 64, alignment: .trailing)
                }
                HStack {
                    Text("Break")
                    Slider(value: $draft.restMinutes, in: 1...30, step: 1)
                    Text("\(Int(draft.restMinutes)) min")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 64, alignment: .trailing)
                }
                Toggle("Pause until I start the next phase", isOn: $draft.focusPauseBetweenPhases)
                Toggle("Notify on phase change", isOn: $draft.focusNotifications)
                Toggle("Play sound on phase change", isOn: $draft.focusSoundEnabled)
                Picker("Sound", selection: $draft.focusSoundName) {
                    ForEach(FocusSound.available, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .disabled(!draft.focusSoundEnabled)
                Stepper(value: $draft.focusSoundRepeatCount, in: 1...5, step: 1) {
                    Text("Repeat \(draft.focusSoundRepeatCount)×")
                }
                .disabled(!draft.focusSoundEnabled)
                Stepper(value: $draft.focusSoundRepeatInterval, in: 0.20...1.00, step: 0.05) {
                    Text(String(format: "Spacing %.2fs", draft.focusSoundRepeatInterval))
                }
                .disabled(!draft.focusSoundEnabled)
            }
        }
        .formStyle(.grouped)
    }

    private enum FocusSound {
        static let available: [String] = [
            "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero",
            "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"
        ]
    }

    private var detectedVolumes: [DiskMonitor.Volume] {
        DiskMonitor.detectAll()
    }

    private func diskRow(_ volume: DiskMonitor.Volume) -> some View {
        HStack {
            Toggle(volume.name, isOn: Binding(
                get: { volume.isSystem || draft.enabledExternalDiskIDs.contains(volume.id) },
                set: { enabled in
                    guard !volume.isSystem else { return }
                    if enabled {
                        draft.enabledExternalDiskIDs.insert(volume.id)
                    } else {
                        draft.enabledExternalDiskIDs.remove(volume.id)
                    }
                }
            ))
            .disabled(volume.isSystem)
            Spacer()
            if volume.isSystem {
                Text("system")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var systemForm: some View {
        Form {
            Section("Sampling") {
                HStack {
                    Slider(value: $draft.samplingInterval, in: 1.0...10.0, step: 0.5)
                    Text(String(format: "%.1fs", draft.samplingInterval))
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 48, alignment: .trailing)
                }
            }
            Section("Overlay") {
                HStack {
                    Text("Width")
                    Slider(value: $draft.overlayWidth, in: 320...1200, step: 10)
                    Text(String(format: "%.0f", draft.overlayWidth))
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 48, alignment: .trailing)
                }
                HStack {
                    Text("Position")
                    Spacer()
                    Button("Reset to Default", action: onResetPosition)
                }
                Toggle("Thin mode", isOn: $draft.thinMode)
                Text("Halves the bar, hides gauge labels, and truncates lyrics to a single line.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("System") {
                Toggle("Launch at login", isOn: $draft.launchAtLogin)
                Toggle("Auto-hide when a fullscreen app is frontmost", isOn: $draft.autoHideOnFullscreen)
                Toggle("Show Wi-Fi name and public IP in expanded network", isOn: $draft.showWiFiInfo)
                if draft.showWiFiInfo {
                    Text("Wi-Fi SSID requires Location permission. Public IP is fetched from api.ipify.org.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func tileRow(tile: Tile, index: Int) -> some View {
        HStack {
            TilePreview(tile: tile, store: demoStore)
            Toggle(tile.label, isOn: Binding(
                get: { draft.isVisible(tile) },
                set: { draft.setVisible(tile, $0) }
            ))
            Spacer()
            Button {
                move(from: index, to: index - 1)
            } label: {
                Image(systemName: "arrow.up")
            }
            .buttonStyle(.borderless)
            .disabled(index == 0)
            Button {
                move(from: index, to: index + 1)
            } label: {
                Image(systemName: "arrow.down")
            }
            .buttonStyle(.borderless)
            .disabled(index == draft.tileOrder.count - 1)
        }
    }

    private func move(from: Int, to: Int) {
        guard to >= 0, to < draft.tileOrder.count, from != to else { return }
        let tile = draft.tileOrder.remove(at: from)
        draft.tileOrder.insert(tile, at: to)
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Preview")
                .font(.caption)
                .foregroundStyle(.secondary)
            LyricBarView(store: demoStore, settings: draft)
                .frame(width: min(draft.overlayWidth, 488), height: previewHeight)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var previewHeight: CGFloat {
        let top: CGFloat = (draft.showSpectrum && draft.spectrumPosition == .above)
            ? LyricBarView.spectrumStripHeight + LyricBarView.bannerSpacing
            : LyricBarView.bannerTotalHeight
        let bottom: CGFloat = (draft.showSpectrum && draft.spectrumPosition == .below)
            ? LyricBarView.spectrumStripTotalHeight
            : 0
        let bar: CGFloat = draft.thinMode ? OverlayWindow.thinBarHeight : OverlayWindow.fullBarHeight
        return bar + top + bottom
    }

    private func apply() {
        let loginChanged = draft.launchAtLogin != live.launchAtLogin
        if loginChanged {
            do {
                try LoginItem.set(draft.launchAtLogin)
            } catch {
                draft.launchAtLogin = live.launchAtLogin
                onApplyError(error)
                return
            }
        }
        live.apply(from: draft)
        live.save()
        live.onApplied?()
    }
}

private struct TilePreview: View {
    let tile: Tile
    let store: MonitorStore

    var body: some View {
        content
            .frame(width: 46, height: 36, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.black.opacity(0.45))
            )
    }

    @ViewBuilder
    private var content: some View {
        switch tile {
        case .cpu:
            RingGauge(
                percent: store.cpuPercent,
                label: "CPU",
                tint: Color(red: 0.38, green: 0.78, blue: 1.0)
            )
        case .gpu:
            RingGauge(
                percent: store.gpuPercent,
                label: "GPU",
                tint: Color(red: 0.75, green: 0.55, blue: 1.0)
            )
        case .mem:
            RingGauge(
                percent: store.memPercent,
                label: "MEM",
                tint: Color(red: 1.0, green: 0.72, blue: 0.30)
            )
        case .network:
            networkSample
        case .disk:
            if let volume = store.disks.first {
                DiskDotsGauge(volume: volume, showLabel: false)
            }
        case .battery:
            BatteryTile(percent: store.batteryPercent, charging: store.batteryCharging)
        case .weather:
            WeatherTile(sample: store.weather, unit: .celsius)
        case .air:
            AirTile(sample: store.airQuality)
        case .focus:
            FocusTile(timer: store.focus)
        case .calendar:
            if let event = store.calendarEvent {
                CalendarTile(event: event, now: Date())
            } else {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
            }
        case .claude:
            ClaudeTile(state: store.claudeState)
        }
    }

    private var networkSample: some View {
        VStack(alignment: .trailing, spacing: 1) {
            HStack(spacing: 2) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Text("1.2M")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            HStack(spacing: 2) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Text("180K")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
}
