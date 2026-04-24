import SwiftUI

struct IdleView: View {
    let event: CalendarEventSample?
    var weather: WeatherSample? = nil
    var weatherUnit: WeatherUnit = .celsius
    let now: Date

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(primaryLine)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(secondaryLine)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }

    private enum Mode { case event, weather, clock }

    private var mode: Mode {
        if event != nil { return .event }
        if weather != nil { return .weather }
        return .clock
    }

    private var iconName: String {
        switch mode {
        case .event: return "calendar"
        case .weather:
            guard let weather else { return "cloud.fill" }
            return WeatherSymbol.name(for: weather.code)
        case .clock: return "clock.fill"
        }
    }

    private var primaryLine: String {
        switch mode {
        case .event:
            return event?.title ?? ""
        case .weather:
            guard let weather else { return "" }
            return WeatherNarrator.primary(sample: weather, unit: weatherUnit)
        case .clock:
            return Self.timeFormatter.string(from: now)
        }
    }

    private var secondaryLine: String {
        switch mode {
        case .event:
            guard let event else { return "" }
            if event.isOngoing {
                let minutesLeft = max(0, Int(event.end.timeIntervalSince(now) / 60))
                return "ends in \(minutesLeft)m"
            }
            let minutesUntil = max(0, Int(event.start.timeIntervalSince(now) / 60))
            if minutesUntil <= 1 { return "now" }
            if minutesUntil < 60 { return "in \(minutesUntil)m" }
            return Self.timeFormatter.string(from: event.start)
        case .weather:
            guard let weather else { return "" }
            return WeatherNarrator.secondary(sample: weather, now: now)
        case .clock:
            return Self.dateFormatter.string(from: now)
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("HH:mm")
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEE MMM d")
        return f
    }()
}
