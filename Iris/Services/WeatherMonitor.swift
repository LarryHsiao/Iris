import Foundation

struct WeatherSample: Equatable {
    let temperatureC: Double
    let code: Int
    let city: String?
}

actor WeatherMonitor {
    private struct Location {
        let lat: Double
        let lon: Double
        let city: String?
    }

    private var cachedLocation: Location?

    func sample() async -> WeatherSample? {
        if cachedLocation == nil {
            cachedLocation = await fetchLocation()
        }
        guard let location = cachedLocation else { return nil }
        return await fetchWeather(location: location)
    }

    private func fetchLocation() async -> Location? {
        struct Response: Decodable {
            let success: Bool?
            let latitude: Double
            let longitude: Double
            let city: String?
        }
        guard let url = URL(string: "https://ipwho.is/") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let loc = try JSONDecoder().decode(Response.self, from: data)
            if let success = loc.success, success == false { return nil }
            return Location(lat: loc.latitude, lon: loc.longitude, city: loc.city)
        } catch {
            return nil
        }
    }

    private func fetchWeather(location: Location) async -> WeatherSample? {
        struct Response: Decodable {
            struct Current: Decodable {
                let temperature_2m: Double
                let weather_code: Int
            }
            let current: Current
        }
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.lat)),
            URLQueryItem(name: "longitude", value: String(location.lon)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code")
        ]
        guard let url = components?.url else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let resp = try JSONDecoder().decode(Response.self, from: data)
            return WeatherSample(
                temperatureC: resp.current.temperature_2m,
                code: resp.current.weather_code,
                city: location.city
            )
        } catch {
            return nil
        }
    }
}

enum WeatherSymbol {
    static func name(for code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 56, 57: return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67, 80, 81, 82: return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
        case 95: return "cloud.bolt.rain.fill"
        case 96, 99: return "cloud.bolt.fill"
        default: return "questionmark.circle"
        }
    }
}
