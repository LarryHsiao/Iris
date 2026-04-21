import AppKit
import SwiftUI

private final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

final class OverlayWindow: NSWindow {
    private static let positionKey = "OverlayWindow.origin"

    init<Content: View>(rootView: Content) {
        let visible = NSScreen.main?.visibleFrame ?? .zero
        let height: CGFloat = 56
        let width = max(visible.width * 0.24, 448)
        let defaultOrigin = NSPoint(
            x: visible.origin.x + (visible.width - width) / 2,
            y: visible.origin.y + visible.height - height
        )
        let origin = OverlayWindow.restoredOrigin(size: NSSize(width: width, height: height))
            ?? defaultOrigin
        let rect = NSRect(origin: origin, size: NSSize(width: width, height: height))
        super.init(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        level = .screenSaver
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        contentView = DraggableHostingView(rootView: rootView)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowDidMove(_:)),
            name: NSWindow.didMoveNotification,
            object: self
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    @objc private func handleWindowDidMove(_ note: Notification) {
        UserDefaults.standard.set(
            NSStringFromPoint(frame.origin),
            forKey: OverlayWindow.positionKey
        )
    }

    private static func restoredOrigin(size: NSSize) -> NSPoint? {
        guard let stored = UserDefaults.standard.string(forKey: positionKey) else { return nil }
        let origin = NSPointFromString(stored)
        let rect = NSRect(origin: origin, size: size)
        let onScreen = NSScreen.screens.contains { $0.visibleFrame.intersects(rect) }
        return onScreen ? origin : nil
    }
}
