import SwiftUI

struct CPUChartView: View {
    let samples: [Double]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let count = max(samples.count, 2)
            let step = count > 1 ? w / CGFloat(count - 1) : w
            let points: [CGPoint] = samples.enumerated().map { i, v in
                let clamped = min(max(v, 0), 100) / 100
                return CGPoint(x: CGFloat(i) * step, y: h - CGFloat(clamped) * h)
            }

            ZStack {
                if points.count >= 2 {
                    Path { p in
                        p.move(to: CGPoint(x: points.first!.x, y: h))
                        for pt in points { p.addLine(to: pt) }
                        p.addLine(to: CGPoint(x: points.last!.x, y: h))
                        p.closeSubpath()
                    }
                    .fill(Color.white.opacity(0.15))

                    Path { p in
                        p.move(to: points[0])
                        for pt in points.dropFirst() { p.addLine(to: pt) }
                    }
                    .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }
}
