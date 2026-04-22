import SwiftUI

struct DiskDotsGauge: View {
    let volume: DiskMonitor.Volume

    static let dotSize: CGFloat = 1
    static let gridSize: CGFloat = 22
    static let count: Int = 196

    private static let positions: [CGPoint] = {
        let maxRadius = (gridSize - dotSize) / 2
        let center = gridSize / 2
        let goldenAngle = Double.pi * (3 - sqrt(5))
        var out: [CGPoint] = []
        for i in 0..<count {
            let angle = Double(i) * goldenAngle
            let normalized = sqrt(Double(i) / Double(count - 1))
            let r = CGFloat(normalized) * maxRadius
            out.append(CGPoint(
                x: center + r * CGFloat(cos(angle)),
                y: center + r * CGFloat(sin(angle))
            ))
        }
        return out
    }()

    private var filled: Int {
        let fraction = max(0, min(1, volume.freePercent / 100))
        return Int((fraction * Double(Self.positions.count)).rounded())
    }

    private var tint: Color {
        if volume.freePercent < 5 { return Color(red: 1.0, green: 0.35, blue: 0.35) }
        if volume.freePercent < 20 { return Color(red: 1.0, green: 0.78, blue: 0.30) }
        return Color(red: 0.38, green: 0.86, blue: 0.46)
    }

    var body: some View {
        VStack(spacing: 1) {
            ZStack {
                ForEach(Array(Self.positions.enumerated()), id: \.offset) { index, point in
                    Circle()
                        .fill(index < filled ? tint : Color.white.opacity(0.18))
                        .frame(width: Self.dotSize, height: Self.dotSize)
                        .position(point)
                }
            }
            .frame(width: Self.gridSize, height: Self.gridSize)
            Text(volume.name)
                .font(.system(size: 7, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 40)
        }
    }
}
