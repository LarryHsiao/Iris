import AppKit
import SwiftUI

final class OverlayWindow: NSWindow {
    private var mouseUpMonitor: Any?

    init<Content: View>(rootView: Content) {
        let visible = NSScreen.main?.visibleFrame ?? .zero
        let height: CGFloat = 28
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
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        contentView = NSHostingView(rootView: rootView)

        mouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            if event.window === self {
                self?.snapToTop()
            }
            return event
        }
    }

    deinit {
        if let mouseUpMonitor {
            NSEvent.removeMonitor(mouseUpMonitor)
        }
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    private func snapToTop() {
        let center = NSPoint(x: frame.midX, y: frame.midY)
        let screen = NSScreen.screens.first { $0.frame.contains(center) }
            ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }
        let targetY = visible.origin.y + visible.height - frame.height
        let clampedX = min(max(frame.origin.x, visible.origin.x),
                           visible.origin.x + visible.width - frame.width)
        let target = NSPoint(x: clampedX, y: targetY)
        guard abs(frame.origin.x - target.x) > 0.5 || abs(frame.origin.y - target.y) > 0.5 else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            ctx.allowsImplicitAnimation = true
            animator().setFrameOrigin(target)
        }
    }
}
