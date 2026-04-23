import EventKit
import Foundation

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
    private(set) var authorized = false

    func requestAccessIfNeeded() async {
        let current = EKEventStore.authorizationStatus(for: .event)
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
        do {
            authorized = try await store.requestFullAccessToEvents()
        } catch {
            print("[CalendarMonitor] access request failed: \(error)")
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
}
