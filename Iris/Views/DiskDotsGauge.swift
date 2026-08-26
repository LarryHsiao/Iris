import SwiftUI

struct DiskDotsGauge: View {
    let volume: DiskMonitor.Volume
    let showLabel: Bool
    var reserveLabelSpace: Bool = true

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

    private static let units: [(divisor: Double, suffix: String)] = [
        (1_000_000_000_000, "TB"),
        (1_000_000_000, "GB"),
        (1_000_000, "MB"),
    ]

    static func freeSpaceLabel(bytes: Int64) -> String {
        for (index, unit) in units.enumerated() where Double(bytes) >= unit.divisor {
            let rounded = (Double(bytes) / unit.divisor).rounded()
            if rounded >= 1000, index > 0 {
                let larger = units[index - 1]
                let biggerValue = Int((Double(bytes) / larger.divisor).rounded())
                return "\(biggerValue) \(larger.suffix)"
            }
            return "\(Int(rounded)) \(unit.suffix)"
        }
        return "\(bytes) B"
    }

    private var freeSpaceText: String {
        Self.freeSpaceLabel(bytes: volume.freeBytes)
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
            if showLabel {
                Text(freeSpaceText)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            } else if reserveLabelSpace {
                Text(freeSpaceText)
                    .font(.system(size: 7, weight: .medium))
                    .hidden()
            }
        }
        .help(volume.name)
    }
}
