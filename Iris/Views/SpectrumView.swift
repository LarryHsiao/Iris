import SwiftUI

struct SpectrumView: View {
    let bands: [Float]
    var tint: Color = Color(red: 0.11, green: 0.84, blue: 0.38)
    var flipped: Bool = false
    var lastActive: Date = .now

    static let idleThreshold: TimeInterval = 10
    static let fadeDuration: TimeInterval = 1.0

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.2)) { context in
            content
                .opacity(opacity(at: context.date))
        }
    }

    private var content: some View {
        GeometryReader { geo in
            let bandCount = max(bands.count, 1)
            let gap: CGFloat = 1
            let totalGap = gap * CGFloat(max(bandCount - 1, 0))
            let barWidth = max(1, (geo.size.width - totalGap) / CGFloat(bandCount))
            HStack(alignment: flipped ? .top : .bottom, spacing: gap) {
                ForEach(0..<bandCount, id: \.self) { i in
                    let value = CGFloat(bands[i])
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(tint)
                        .frame(width: barWidth, height: max(1, value * geo.size.height))
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: flipped ? .top : .bottom
            )
            .animation(.linear(duration: 0.08), value: bands)
        }
    }

    private func opacity(at date: Date) -> Double {
        let idle = date.timeIntervalSince(lastActive)
        if idle <= Self.idleThreshold { return 1 }
        let extra = idle - Self.idleThreshold
        return max(0, 1 - extra / Self.fadeDuration)
    }
}
