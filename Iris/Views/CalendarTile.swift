import SwiftUI

struct CalendarTile: View {
    let event: CalendarEventSample
    let now: Date
    var showLabel: Bool = true
    var imminentMinutes: Double = 5

    private var soonThresholdMinutes: Double { imminentMinutes * 2 }
    private var imminentThresholdMinutes: Double { imminentMinutes }

    var body: some View {
        VStack(spacing: 1) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isImminent)) { context in
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .opacity(pulseOpacity(at: context.date))
                    Image(systemName: "calendar")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 22, height: 22)
            }
            if showLabel {
                Text(countdownLabel)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }

    private var progress: Double {
        let horizon: TimeInterval = 60 * 60
        if event.isOngoing {
            let total = event.end.timeIntervalSince(event.start)
            guard total > 0 else { return 1 }
            return max(0, min(1, 1 - event.end.timeIntervalSince(now) / total))
        }
        let remaining = max(0, event.start.timeIntervalSince(now))
        return max(0, min(1, 1 - remaining / horizon))
    }

    private var minutesUntilStart: Double {
        event.start.timeIntervalSince(now) / 60
    }

    private var isImminent: Bool {
        !event.isOngoing
            && minutesUntilStart > 0
            && minutesUntilStart <= imminentThresholdMinutes
    }

    private var tint: Color {
        if event.isOngoing {
            return Color(red: 0.38, green: 0.85, blue: 0.55)
        }
        let m = minutesUntilStart
        if m <= imminentThresholdMinutes {
            return Color(red: 0.96, green: 0.40, blue: 0.28)
        }
        if m <= soonThresholdMinutes {
            return Color(red: 0.98, green: 0.85, blue: 0.20)
        }
        return Color(red: 0.55, green: 0.68, blue: 0.85)
    }

    private func pulseOpacity(at date: Date) -> Double {
        guard isImminent else { return 1.0 }
        let phase = sin(date.timeIntervalSinceReferenceDate * 2 * .pi)
        return 0.55 + 0.45 * (phase * 0.5 + 0.5)
    }

    private var countdownLabel: String {
        if event.isOngoing {
            let minutesLeft = max(0, Int(event.end.timeIntervalSince(now) / 60))
            return minutesLeft <= 0 ? "end" : "\(minutesLeft)m"
        }
        let minutesUntil = Int(event.start.timeIntervalSince(now) / 60)
        if minutesUntil <= 0 { return "now" }
        return "\(minutesUntil)m"
    }
}
