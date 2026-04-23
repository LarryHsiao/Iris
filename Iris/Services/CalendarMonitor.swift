import AppKit
import EventKit
import Foundation
import OSLog

struct CalendarEventSample: Equatable {
    let title: String
    let start: Date
    let end: Date

    var isOngoing: Bool { Date() >= start && Date() < end }
    var isFuture: Bool { Date() < start }
}

@MainActor
final class CalendarMonitor {
    private let store = EKEventStore()
    private let log = Logger(subsystem: "com.larryhsiao.Iris", category: "Calendar")
    private(set) var authorized = false

    func requestAccessIfNeeded() async {
        let current = EKEventStore.authorizationStatus(for: .event)
        log.info("EventKit status on entry: \(current.rawValue, privacy: .public)")
        switch current {
        case .fullAccess:
            authorized = true
            return
        case .denied, .restricted:
            authorized = false
            return
        default:
            break
        }
        NSApp.activate(ignoringOtherApps: true)
        do {
            let granted = try await store.requestFullAccessToEvents()
            let after = EKEventStore.authorizationStatus(for: .event)
            authorized = granted
            log.info("EventKit request: granted=\(granted, privacy: .public), status=\(after.rawValue, privacy: .public)")
            if !granted, after == .notDetermined {
                Self.presentSilentFailureAlert()
            }
        } catch {
            log.error("EventKit request failed: \(String(describing: error), privacy: .public)")
            authorized = false
        }
    }

    func nextEvent(within window: TimeInterval = 60 * 60) -> CalendarEventSample? {
        guard authorized else { return nil }
        let now = Date()
        let horizon = now.addingTimeInterval(window)
        let calendars = store.calendars(for: .event)
        guard !calendars.isEmpty else { return nil }
        let predicate = store.predicateForEvents(
            withStart: now.addingTimeInterval(-60 * 60 * 12),
            end: horizon,
            calendars: calendars
        )
        let candidates = store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .filter { $0.endDate > now && $0.startDate < horizon }
            .sorted { lhs, rhs in
                if lhs.startDate != rhs.startDate {
                    return lhs.startDate < rhs.startDate
                }
                return lhs.endDate < rhs.endDate
            }
        guard let event = candidates.first else { return nil }
        return CalendarEventSample(
            title: event.title ?? "Event",
            start: event.startDate,
            end: event.endDate
        )
    }

    private static func presentSilentFailureAlert() {
        let alert = NSAlert()
        alert.messageText = "Calendar permission wasn't requested"
        alert.informativeText = """
            macOS didn't show the Calendar permission prompt. This usually means the app wasn't focused when asking.
            Toggle Calendar off and on again, or grant access via System Settings → Privacy & Security → Calendars.
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "OK")
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }
}
