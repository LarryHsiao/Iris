import AppKit

@MainActor
final class FullscreenMonitor {
    var onChange: ((Bool) -> Void)?
    private(set) var isFullscreen: Bool = false
    private var tokens: [NSObjectProtocol] = []

    func start() {
        stop()
        let nc = NSWorkspace.shared.notificationCenter
        let names: [NSNotification.Name] = [
            NSWorkspace.activeSpaceDidChangeNotification,
            NSWorkspace.didActivateApplicationNotification
        ]
        for name in names {
            let token = nc.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.recheck() }
            }
            tokens.append(token)
        }
        recheck()
    }

    func stop() {
        let nc = NSWorkspace.shared.notificationCenter
        for token in tokens { nc.removeObserver(token) }
        tokens.removeAll()
    }

    private func recheck() {
        let value = Self.frontmostAppCoversScreen()
        if value != isFullscreen {
            isFullscreen = value
            onChange?(value)
        }
    }

    private static func frontmostAppCoversScreen() -> Bool {
        guard let frontPID = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
            return false
        }
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        let screens = NSScreen.screens.map { $0.frame.size }
        for info in windows {
            guard
                let pid = info[kCGWindowOwnerPID as String] as? pid_t, pid == frontPID,
                let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                let boundsDict = info[kCGWindowBounds as String] as? [String: CGFloat]
            else { continue }
            let width = boundsDict["Width"] ?? 0
            let height = boundsDict["Height"] ?? 0
            for size in screens {
                if width >= size.width - 1 && height >= size.height - 1 {
                    return true
                }
            }
        }
        return false
    }
}
