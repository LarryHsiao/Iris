import CoreGraphics
import Foundation

/// Polls the login session's key-down counter while the typing tile is enabled.
/// The counter is a bare total: which key was pressed is never available here.
@MainActor
final class TypingMonitor {
    private static let pollInterval: TimeInterval = 0.25
    private static let bestKey = "Typing.v1.bestWPM"

    var onUpdate: ((_ wpm: Double?, _ best: Double) -> Void)?

    private var pace = TypingPace(best: UserDefaults.standard.double(forKey: bestKey))
    private var previousCount: UInt32?
    private var timer: Timer?

    func start() {
        guard timer == nil else { return }
        previousCount = Self.keyDownCount()
        timer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        previousCount = nil
    }

    private func tick() {
        let now = Date()
        let count = Self.keyDownCount()
        let typed = Int(count &- (previousCount ?? count))
        previousCount = count
        let bestBefore = pace.best
        pace.record(keystrokes: typed, at: now)
        if pace.best > bestBefore {
            UserDefaults.standard.set(pace.best, forKey: Self.bestKey)
        }
        onUpdate?(pace.wordsPerMinute(at: now), pace.best)
    }

    private static func keyDownCount() -> UInt32 {
        CGEventSource.counterForEventType(.combinedSessionState, eventType: .keyDown)
    }
}
