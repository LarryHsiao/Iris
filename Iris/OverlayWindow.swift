import AppKit
import SwiftUI

final class OverlayWindow: NSWindow {
    init<Content: View>(rootView: Content) {
        let visible = NSScreen.main?.visibleFrame ?? .zero
        let height: CGFloat = 28
        let rect = NSRect(
            x: visible.origin.x,
            y: visible.origin.y + visible.height - height,
            width: visible.width,
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
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        contentView = NSHostingView(rootView: rootView)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
