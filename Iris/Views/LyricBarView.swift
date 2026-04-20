import SwiftUI

struct LyricBarView: View {
    let store: MonitorStore

    var body: some View {
        HStack(spacing: 16) {
            Spacer(minLength: 12)
            Text(store.currentLine)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 12)
            Text(String(format: "CPU %3.0f%%", store.cpuPercent))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.trailing, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.45))
    }
}
