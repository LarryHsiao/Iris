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
    private static let barHeight: CGFloat = 56
    private static var height: CGFloat { barHeight + LyricBarView.bannerTotalHeight }
    static let minWidth: CGFloat = 320
    static let maxWidth: CGFloat = 1200

    init<Content: View>(rootView: Content, width: CGFloat) {
        let visible = NSScreen.main?.visibleFrame ?? .zero
        let size = NSSize(width: OverlayWindow.clamp(width), height: OverlayWindow.height)
        let origin = OverlayWindow.restoredOrigin(size: size)
            ?? OverlayWindow.defaultOrigin(visible: visible, size: size)
        let rect = NSRect(origin: origin, size: size)
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

    func setWidth(_ width: CGFloat) {
        var next = frame
        next.size.width = OverlayWindow.clamp(width)
        setFrame(next, display: true)
    }

    func resetPosition() {
        let visible = NSScreen.main?.visibleFrame ?? .zero
        let origin = OverlayWindow.defaultOrigin(visible: visible, size: frame.size)
        UserDefaults.standard.removeObject(forKey: OverlayWindow.positionKey)
        setFrameOrigin(origin)
    }

    @objc private func handleWindowDidMove(_ note: Notification) {
        UserDefaults.standard.set(
            NSStringFromPoint(frame.origin),
            forKey: OverlayWindow.positionKey
        )
    }

    private static func clamp(_ width: CGFloat) -> CGFloat {
        min(max(width, minWidth), maxWidth)
    }

    private static func defaultOrigin(visible: NSRect, size: NSSize) -> NSPoint {
        NSPoint(
            x: visible.origin.x + (visible.width - size.width) / 2,
            y: visible.origin.y + visible.height - size.height
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
