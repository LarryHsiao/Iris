import AppKit
import SwiftUI

@MainActor
final class SettingsWindow: NSObject, NSWindowDelegate {
    private let window: NSWindow
    private let hosting: NSHostingController<SettingsView>

    init(
        settings: Settings,
        demoStore: MonitorStore,
        onResetPosition: @escaping () -> Void
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Iris Settings"
        window.isReleasedWhenClosed = false

        var errorClosure: ((Error) -> Void)?
        let view = SettingsView(
            live: settings,
            demoStore: demoStore,
            onResetPosition: onResetPosition,
            onClose: { [weak window] in window?.close() },
            onApplyError: { error in errorClosure?(error) }
        )
        let hosting = NSHostingController(rootView: view)
        hosting.sizingOptions = [.preferredContentSize]
        window.contentViewController = hosting

        self.window = window
        self.hosting = hosting
        super.init()
        window.delegate = self

        errorClosure = { [weak self] error in self?.presentError(error) }
    }

    func show() {
        if !window.isVisible { window.center() }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func presentError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Couldn't update login item"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.beginSheetModal(for: window, completionHandler: nil)
    }
}
