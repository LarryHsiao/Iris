import Foundation

/// Rolling typing speed built from keystroke counts.
/// Holds timestamps and counts only; it never sees which key was pressed.
nonisolated struct TypingPace {
    static let window: TimeInterval = 5
    static let idleAfter: TimeInterval = 2
    private static let keystrokesPerWord = 5.0
    private static let secondsPerMinute = 60.0

    /// Highest speed reached after a whole window of unbroken typing.
    private(set) var best: Double

    private var strokes: [(at: Date, count: Int)] = []
    private var runStartedAt: Date?
    private var lastKeyAt: Date?

    init(best: Double = 0) {
        self.best = best
    }

    mutating func record(keystrokes: Int, at now: Date) {
        guard keystrokes > 0 else { return }
        if isIdle(at: now) { runStartedAt = now }
        lastKeyAt = now
        strokes.removeAll { now.timeIntervalSince($0.at) >= Self.window }
        strokes.append((at: now, count: keystrokes))
        if isSustained(at: now), let speed = wordsPerMinute(at: now), speed > best {
            best = speed
        }
    }

    /// Words per minute over the last window, or nil while idle.
    func wordsPerMinute(at now: Date) -> Double? {
        guard !isIdle(at: now) else { return nil }
        let keys = strokes
            .filter { now.timeIntervalSince($0.at) < Self.window }
            .reduce(0) { $0 + $1.count }
        return Double(keys) / Self.keystrokesPerWord * (Self.secondsPerMinute / Self.window)
    }

    private func isIdle(at now: Date) -> Bool {
        guard let lastKeyAt else { return true }
        return now.timeIntervalSince(lastKeyAt) >= Self.idleAfter
    }

    /// True once the current unbroken run has filled a whole window.
    private func isSustained(at now: Date) -> Bool {
        guard let runStartedAt else { return false }
        return now.timeIntervalSince(runStartedAt) >= Self.window
    }
}
