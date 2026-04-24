import SwiftUI

struct RingGauge: View {
    let percent: Double
    let label: String
    let tint: Color
    var showLabel: Bool = true

    var body: some View {
        VStack(spacing: 1) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: min(max(percent / 100, 0), 1))
                    .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(percent.rounded()))")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 22, height: 22)
            if showLabel {
                Text(label)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}
