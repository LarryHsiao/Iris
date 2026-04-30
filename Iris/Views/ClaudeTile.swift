import SwiftUI

struct ClaudeTile: View {
    let state: ClaudeState
    var showLabel: Bool = true

    var body: some View {
        if let oldest = state.oldest {
            tileBody(for: oldest)
                .help(helpText(for: oldest))
        }
    }

    private func tileBody(for session: ClaudeSession) -> some View {
        TimelineView(.periodic(from: .now, by: 0.05)) { context in
            VStack(spacing: 1) {
                ZStack {
                    Image(systemName: "sparkle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(red: 0.95, green: 0.78, blue: 0.55))
                        .rotationEffect(.degrees(rotation(at: context.date)))
                        .opacity(pulse(at: context.date))
                }
                .frame(width: 22, height: 22)
                if showLabel {
                    Text(label(for: session, now: context.date))
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
        }
    }

    private func label(for session: ClaudeSession, now: Date) -> String {
        let elapsed = elapsed(since: session.since, now: now)
        if state.sessions.count > 1 {
            return "\(state.sessions.count)·\(elapsed)"
        }
        return elapsed
    }

    private func helpText(for session: ClaudeSession) -> String {
        if state.sessions.count == 1 {
            let suffix = session.tool.map { " · \($0)" } ?? ""
            return "Claude is thinking — \(session.project)\(suffix)"
        }
        let names = state.sessions.map(\.project).joined(separator: ", ")
        return "Claude is thinking — \(state.sessions.count) sessions (\(names))"
    }

    private func elapsed(since: Date, now: Date) -> String {
        let seconds = Int(now.timeIntervalSince(since).rounded())
        if seconds < 60 { return "\(max(seconds, 0))s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        return "\(hours)h"
    }

    private func rotation(at date: Date) -> Double {
        let secondsPerRevolution = 4.0
        let phase = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: secondsPerRevolution)
            / secondsPerRevolution
        return phase * 360
    }

    private func pulse(at date: Date) -> Double {
        let phase = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: 1.4) / 1.4
        return 0.55 + 0.45 * (0.5 - 0.5 * cos(2 * .pi * phase))
    }
}
