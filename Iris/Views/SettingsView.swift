import SwiftUI

struct SettingsView: View {
    @Bindable var live: Settings
    let demoStore: MonitorStore
    var onResetPosition: () -> Void
    var onClose: () -> Void
    var onApplyError: (Error) -> Void

    @State private var draft: Settings

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
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { onClose() }
                    .keyboardShortcut(.cancelAction)
                Button("Apply", action: apply)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 520)
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
                Toggle("Notify on phase change", isOn: $draft.focusNotifications)
            }
        }
        .formStyle(.grouped)
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
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var previewHeight: CGFloat {
        let top: CGFloat = (draft.showSpectrum && draft.spectrumPosition == .above)
            ? LyricBarView.spectrumStripHeight + LyricBarView.bannerSpacing
            : LyricBarView.bannerTotalHeight
        let bottom: CGFloat = (draft.showSpectrum && draft.spectrumPosition == .below)
            ? LyricBarView.spectrumStripTotalHeight
            : 0
        return 56 + top + bottom
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
        onClose()
    }
}
