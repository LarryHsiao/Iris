import SwiftUI

struct Sparkline: View {
    let samples: [Double]
    let tint: Color
    let maxValue: Double?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if samples.count >= 2 {
                    content(size: geo.size)
                }
            }
        }
    }

    @ViewBuilder
    private func content(size: CGSize) -> some View {
        let upper = max(maxValue ?? (samples.max() ?? 1), 0.0001)
        let norm = samples.map { min(max($0 / upper, 0), 1) }
        let step = size.width / CGFloat(max(norm.count - 1, 1))
        let points = norm.enumerated().map { i, v in
            CGPoint(x: CGFloat(i) * step, y: size.height - CGFloat(v) * size.height)
        }
        ZStack {
            Path { p in
                guard let first = points.first, let last = points.last else { return }
                p.move(to: CGPoint(x: first.x, y: size.height))
                p.addLine(to: first)
                for pt in points.dropFirst() { p.addLine(to: pt) }
                p.addLine(to: CGPoint(x: last.x, y: size.height))
                p.closeSubpath()
            }
            .fill(tint.opacity(0.22))
            Path { p in
                guard let first = points.first else { return }
                p.move(to: first)
                for pt in points.dropFirst() { p.addLine(to: pt) }
            }
            .stroke(tint, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
        }
    }
}
