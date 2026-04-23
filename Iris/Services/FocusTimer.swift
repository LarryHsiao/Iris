import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class FocusTimer {
    enum Phase { case focus, rest }
    enum Mode { case idle, running, paused }

    var phase: Phase = .focus
    var mode: Mode = .idle
    var remaining: TimeInterval = 25 * 60

    var focusDuration: TimeInterval = 25 * 60
    var restDuration: TimeInterval = 5 * 60
    var notificationsEnabled: Bool = true

    private var endDate: Date?
    private var ticker: Timer?
    private var didRequestNotifications = false

    func toggle() {
        switch mode {
        case .idle: startPhase()
        case .running: pause()
        case .paused: resume()
        }
    }

    func reset() {
        ticker?.invalidate()
        ticker = nil
        phase = .focus
        mode = .idle
        remaining = focusDuration
        endDate = nil
    }

    func skipPhase() {
        advancePhase()
        remaining = phaseDuration()
        if mode == .running {
            endDate = Date().addingTimeInterval(remaining)
        } else {
            endDate = nil
        }
    }

    func applyDurations(focus: TimeInterval, rest: TimeInterval) {
        focusDuration = focus
        restDuration = rest
        if mode == .idle {
            remaining = phaseDuration()
        }
    }

    var formattedRemaining: String {
        let total = max(0, Int(remaining.rounded(.up)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    var displayMinutes: Int {
        let seconds = mode == .idle ? phaseDuration() : remaining
        return max(0, Int((seconds / 60).rounded(.up)))
    }

    var progress: Double {
        let duration = phaseDuration()
        guard duration > 0, mode != .idle else { return 0 }
        return max(0, min(1, 1 - remaining / duration))
    }

    private func startPhase() {
        remaining = phaseDuration()
        endDate = Date().addingTimeInterval(remaining)
        mode = .running
        scheduleTick()
        requestNotificationPermissionIfNeeded()
    }

    private func pause() {
        guard mode == .running, let end = endDate else { return }
        remaining = max(0, end.timeIntervalSinceNow)
        mode = .paused
        ticker?.invalidate()
        ticker = nil
    }

    private func resume() {
        guard mode == .paused else { return }
        endDate = Date().addingTimeInterval(remaining)
        mode = .running
        scheduleTick()
    }

    private func phaseDuration() -> TimeInterval {
        phase == .focus ? focusDuration : restDuration
    }

    private func advancePhase() {
        phase = (phase == .focus) ? .rest : .focus
    }

    private func scheduleTick() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        guard mode == .running, let end = endDate else { return }
        let remaining = max(0, end.timeIntervalSinceNow)
        self.remaining = remaining
        if remaining <= 0 {
            completePhase()
        }
    }

    private func completePhase() {
        let finished = phase
        postPhaseEndNotification(finished)
        advancePhase()
        remaining = phaseDuration()
        endDate = Date().addingTimeInterval(remaining)
    }

    private func postPhaseEndNotification(_ finished: Phase) {
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = finished == .focus ? "Focus done" : "Break over"
        content.body = finished == .focus ? "Time for a break." : "Back to work."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func requestNotificationPermissionIfNeeded() {
        guard notificationsEnabled, !didRequestNotifications else { return }
        didRequestNotifications = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
