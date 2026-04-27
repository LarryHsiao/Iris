import SwiftUI

struct AirTile: View {
    let sample: AirQualitySample?
    var showLabel: Bool = true

    var body: some View {
        VStack(spacing: 1) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: ringFill)
                    .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(centerLabel)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 22, height: 22)
            if showLabel {
                Text("AIR")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var ringFill: Double {
        guard let sample else { return 0 }
        return min(1.0, Double(max(0, sample.aqi)) / 100.0)
    }

    private var centerLabel: String {
        guard let sample else { return "—" }
        return "\(sample.aqi)"
    }

    private var tint: Color {
        guard let sample else { return Color.white.opacity(0.4) }
        return AQIBand(aqi: sample.aqi).color
    }
}
