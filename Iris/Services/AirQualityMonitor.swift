import Foundation
import SwiftUI

struct AirQualitySample: Equatable {
    let aqi: Int
    let pm2_5: Double?
    let pm10: Double?
    let grassPollen: Double?
    let treePollen: Double?
    let weedPollen: Double?
}

enum AQIBand {
    case good, fair, moderate, poor, veryPoor, extreme

    init(aqi: Int) {
        switch aqi {
        case ..<20: self = .good
        case ..<40: self = .fair
        case ..<60: self = .moderate
        case ..<80: self = .poor
        case ..<100: self = .veryPoor
        default: self = .extreme
        }
    }

    var label: String {
        switch self {
        case .good: return "Good"
        case .fair: return "Fair"
        case .moderate: return "Mod"
        case .poor: return "Poor"
        case .veryPoor: return "V.Poor"
        case .extreme: return "Hazard"
        }
    }

    var color: Color {
        switch self {
        case .good: return Color(red: 0.35, green: 0.80, blue: 0.45)
        case .fair: return Color(red: 0.65, green: 0.80, blue: 0.30)
        case .moderate: return Color(red: 0.95, green: 0.80, blue: 0.25)
        case .poor: return Color(red: 0.95, green: 0.55, blue: 0.20)
        case .veryPoor: return Color(red: 0.92, green: 0.30, blue: 0.30)
        case .extreme: return Color(red: 0.65, green: 0.25, blue: 0.65)
        }
    }
}

enum PollenLevel {
    case none, low, moderate, high, veryHigh

    static func grass(_ count: Double) -> PollenLevel {
        bucket(count, thresholds: (10, 50, 200))
    }

    static func tree(_ count: Double) -> PollenLevel {
        bucket(count, thresholds: (10, 50, 100))
    }

    static func weed(_ count: Double) -> PollenLevel {
        bucket(count, thresholds: (10, 30, 100))
    }

    private static func bucket(_ count: Double, thresholds: (Double, Double, Double)) -> PollenLevel {
        if count <= 0 { return .none }
        if count < thresholds.0 { return .low }
        if count < thresholds.1 { return .moderate }
        if count < thresholds.2 { return .high }
        return .veryHigh
    }

    var short: String {
        switch self {
        case .none: return "—"
        case .low: return "Low"
        case .moderate: return "Mod"
        case .high: return "High"
        case .veryHigh: return "V.High"
        }
    }
}

actor AirQualityMonitor {
    private struct Location {
        let lat: Double
        let lon: Double
    }

    private var cachedLocation: Location?

    func sample() async -> AirQualitySample? {
        if cachedLocation == nil {
            cachedLocation = await fetchLocation()
        }
        guard let location = cachedLocation else { return nil }
        return await fetchAirQuality(location: location)
    }

    private func fetchLocation() async -> Location? {
        struct Response: Decodable {
            let success: Bool?
            let latitude: Double
            let longitude: Double
        }
        guard let url = URL(string: "https://ipwho.is/") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let loc = try JSONDecoder().decode(Response.self, from: data)
            if let success = loc.success, success == false { return nil }
            return Location(lat: loc.latitude, lon: loc.longitude)
        } catch {
            return nil
        }
    }

    private func fetchAirQuality(location: Location) async -> AirQualitySample? {
        struct Response: Decodable {
            struct Current: Decodable {
                let european_aqi: Double?
                let pm2_5: Double?
                let pm10: Double?
                let grass_pollen: Double?
                let birch_pollen: Double?
                let alder_pollen: Double?
                let olive_pollen: Double?
                let mugwort_pollen: Double?
                let ragweed_pollen: Double?
            }
            let current: Current
        }
        var components = URLComponents(string: "https://air-quality-api.open-meteo.com/v1/air-quality")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.lat)),
            URLQueryItem(name: "longitude", value: String(location.lon)),
            URLQueryItem(
                name: "current",
                value: "european_aqi,pm2_5,pm10,grass_pollen,birch_pollen,alder_pollen,olive_pollen,mugwort_pollen,ragweed_pollen"
            )
        ]
        guard let url = components?.url else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let resp = try JSONDecoder().decode(Response.self, from: data)
            let aqi = Int((resp.current.european_aqi ?? 0).rounded())
            let trees = [resp.current.birch_pollen, resp.current.alder_pollen, resp.current.olive_pollen]
                .compactMap { $0 }
            let weeds = [resp.current.mugwort_pollen, resp.current.ragweed_pollen]
                .compactMap { $0 }
            return AirQualitySample(
                aqi: aqi,
                pm2_5: resp.current.pm2_5,
                pm10: resp.current.pm10,
                grassPollen: resp.current.grass_pollen,
                treePollen: trees.isEmpty ? nil : trees.max(),
                weedPollen: weeds.isEmpty ? nil : weeds.max()
            )
        } catch {
            return nil
        }
    }
}
