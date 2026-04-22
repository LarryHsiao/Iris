import SwiftUI

struct WeatherTile: View {
    let sample: WeatherSample?

    var body: some View {
        VStack(spacing: 1) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(sample == nil ? .white.opacity(0.4) : .white)
                .frame(width: 22, height: 22)
            Text(temperatureString)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var iconName: String {
        guard let sample else { return "cloud.fill" }
        return WeatherSymbol.name(for: sample.code)
    }

    private var temperatureString: String {
        guard let sample else { return "—" }
        return "\(Int(sample.temperatureC.rounded()))°"
    }
}
