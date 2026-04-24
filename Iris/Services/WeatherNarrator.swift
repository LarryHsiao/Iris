import Foundation

enum WeatherNarrator {
    static func primary(sample: WeatherSample, unit: WeatherUnit) -> String {
        "\(conditionPhrase(code: sample.code)), \(temperature(celsius: sample.temperatureC, unit: unit))"
    }

    static func secondary(sample: WeatherSample, now: Date) -> String {
        let time = timeFormatter.string(from: now)
        if let city = sample.city, !city.isEmpty {
            return "\(city) · \(time)"
        }
        return time
    }

    static func temperature(celsius: Double, unit: WeatherUnit) -> String {
        switch unit {
        case .celsius:
            return "\(Int(celsius.rounded()))°"
        case .fahrenheit:
            let f = celsius * 9 / 5 + 32
            return "\(Int(f.rounded()))°"
        }
    }

    private static func conditionPhrase(code: Int) -> String {
        switch code {
        case 0: return "Skies clear"
        case 1, 2: return "A few clouds"
        case 3: return "Under a grey sky"
        case 45, 48: return "A soft fog"
        case 51, 53, 55: return "A light drizzle"
        case 56, 57: return "Freezing drizzle"
        case 61, 63, 80, 81: return "Steady rain"
        case 65, 82: return "Heavy rain"
        case 66, 67: return "Freezing rain"
        case 71, 73, 85: return "Snow falls"
        case 75, 86: return "Heavy snow"
        case 77: return "Snow grains drift"
        case 95: return "Thunder rolls"
        case 96, 99: return "Hail and thunder"
        default: return "The sky holds"
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("HH:mm")
        return f
    }()
}
