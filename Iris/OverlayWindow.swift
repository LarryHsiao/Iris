import AppKit
import SwiftUI

private final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

final class OverlayWindow: NSWindow {
    init<Content: View>(rootView: Content) {
        let visible = NSScreen.main?.visibleFrame ?? .zero
        let height: CGFloat = 56
        let width = visible.width * 0.2
        let rect = NSRect(
            x: visible.origin.x + (visible.width - width) / 2,
            y: visible.origin.y + visible.height - height,
            width: width,
            height: height
        )
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
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
