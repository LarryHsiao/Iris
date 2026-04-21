import SwiftUI

struct BatteryTile: View {
    let percent: Double
    let charging: Bool

    var body: some View {
        VStack(spacing: 1) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: min(max(percent / 100, 0), 1))
                    .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if charging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(Int(percent.rounded()))")
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 22, height: 22)
            Text("BAT")
                .font(.system(size: 7, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var tint: Color {
        if charging { return Color(red: 0.11, green: 0.84, blue: 0.38) }
        if percent <= 20 { return Color(red: 1.0, green: 0.35, blue: 0.35) }
        return Color(red: 0.55, green: 0.95, blue: 0.65)
    }
}
