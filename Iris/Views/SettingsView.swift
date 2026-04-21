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
            Form {
                Section("Left") {
                    Toggle("Lyrics", isOn: $draft.showLyrics)
                    Toggle("Album artwork", isOn: $draft.showArtwork)
                    Toggle("Progress bar", isOn: $draft.showProgress)
                }
                Section("Tiles") {
                    ForEach(Array(draft.tileOrder.enumerated()), id: \.element) { index, tile in
                        tileRow(tile: tile, index: index)
                    }
                }
                Section("Sampling") {
                    HStack {
                        Slider(value: $draft.samplingInterval, in: 1.0...10.0, step: 0.5)
                        Text(String(format: "%.1fs", draft.samplingInterval))
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 48, alignment: .trailing)
                    }
                }
                Section("System") {
                    Toggle("Launch at login", isOn: $draft.launchAtLogin)
                    HStack {
                        Text("Overlay position")
                        Spacer()
                        Button("Reset to Default", action: onResetPosition)
                    }
                }
            }
            .formStyle(.grouped)
            .frame(minHeight: 520)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { onClose() }
                    .keyboardShortcut(.cancelAction)
                Button("Apply", action: apply)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isDirty)
            }
        }
        .padding(16)
        .frame(width: 520)
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
                .frame(height: 56)
                .frame(maxWidth: .infinity)
        }
    }

    private var isDirty: Bool { !live.equals(draft) }

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
