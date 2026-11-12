import SwiftUI

/// Typing speed ring: live words per minute while typing, the personal best while idle.
struct TypingTile: View {
    /// Live speed, or nil while idle.
    let wpm: Double?
    let best: Double
    var showLabel: Bool = true

    private static let idleOpacity = 0.45
    private static let paceTint = Color(red: 0.38, green: 0.82, blue: 0.44)
    private static let recordTint = Color(red: 0.94, green: 0.70, blue: 0.29)

    var body: some View {
        VStack(spacing: 1) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(centre)
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: 16)
            }
            .frame(width: 22, height: 22)
            if showLabel {
                Text("WPM")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .opacity(wpm == nil ? Self.idleOpacity : 1)
        .animation(.easeOut(duration: 0.3), value: wpm == nil)
    }

    /// Live speed against the personal best; empty while idle or before a best exists.
    private var fraction: Double {
        guard let wpm, best > 0 else { return 0 }
        return min(wpm / best, 1)
    }

    private var tint: Color {
        guard let wpm, best > 0, wpm >= best else { return Self.paceTint }
        return Self.recordTint
    }

    private var centre: String {
        if let wpm { return "\(Int(wpm.rounded()))" }
        return best > 0 ? "\(Int(best.rounded()))" : "–"
    }
}
