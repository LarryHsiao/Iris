import SwiftUI

struct FocusTile: View {
    let timer: FocusTimer
    var showLabel: Bool = true

    var body: some View {
        Button(action: { timer.toggle() }) {
            VStack(spacing: 1) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: timer.progress)
                        .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(timer.displayMinutes)")
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: 22, height: 22)
                if showLabel {
                    Text(phaseLabel)
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .opacity(timer.mode == .paused ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(toggleLabel) { timer.toggle() }
            Button("Skip phase") { timer.skipPhase() }
            Button("Reset") { timer.reset() }
        }
    }

    private var tint: Color {
        timer.phase == .focus
            ? Color(red: 1.0, green: 0.32, blue: 0.38)
            : Color(red: 0.38, green: 0.85, blue: 0.55)
    }

    private var phaseLabel: String {
        timer.phase == .focus ? "FOC" : "BRK"
    }

    private var toggleLabel: String {
        switch timer.mode {
        case .idle: return "Start"
        case .running: return "Pause"
        case .paused: return "Resume"
        }
    }
}
