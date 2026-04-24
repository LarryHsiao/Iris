import SwiftUI

struct CalendarTile: View {
    let event: CalendarEventSample
    let now: Date
    var showLabel: Bool = true

    var body: some View {
        VStack(spacing: 1) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "calendar")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 22, height: 22)
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

    private var tint: Color {
        event.isOngoing
            ? Color(red: 0.38, green: 0.85, blue: 0.55)
            : Color(red: 0.95, green: 0.72, blue: 0.32)
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
