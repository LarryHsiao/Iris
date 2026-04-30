import Foundation
import Observation

@Observable
final class MonitorStore {
    static let historyCapacity = 60

    var currentLine: String = "—"
    var cpuPercent: Double = 0
    var hasTrack: Bool = false
    var isPlaying: Bool = false
    var artworkURL: URL?
    var progress: Double = 0
    var memPercent: Double = 0
    var disks: [DiskMonitor.Volume] = []
    var gpuPercent: Double = 0
    var netRxBytesPerSec: Double = 0
    var netTxBytesPerSec: Double = 0
    var batteryPercent: Double = 0
    var batteryCharging: Bool = false
    var batteryPresent: Bool = false
    var weather: WeatherSample?
    var airQuality: AirQualitySample?
    var callInCall: Bool = false
    var callAppName: String?
    var callAppProcessName: String?
    var claudeState: ClaudeState = .idle
    var spectrum: [Float] = Array(repeating: 0, count: AudioCapture.bandCount) {
        didSet {
            if (spectrum.max() ?? 0) > 0.01 {
                spectrumLastActiveAt = Date()
            }
        }
    }
    var spectrumLastActiveAt: Date = .distantPast

    var wifiSSID: String?
    var publicIP: String?

    let focus = FocusTimer()

    var calendarEvent: CalendarEventSample?
    var calendarFollowUp: CalendarEventSample?
    var now: Date = Date()

    var cpuHistory: [Double] = []
    var gpuHistory: [Double] = []
    var memHistory: [Double] = []
    var netRxHistory: [Double] = []
    var netTxHistory: [Double] = []

    var expandedTile: Tile?

    func recordSystemSample() {
        Self.push(&cpuHistory, cpuPercent)
        Self.push(&gpuHistory, gpuPercent)
        Self.push(&memHistory, memPercent)
        Self.push(&netRxHistory, netRxBytesPerSec)
        Self.push(&netTxHistory, netTxBytesPerSec)
    }

    private static func push(_ buf: inout [Double], _ value: Double) {
        buf.append(value)
        if buf.count > historyCapacity {
            buf.removeFirst(buf.count - historyCapacity)
        }
    }

    func playPause() {
        SpotifyClient.playPause()
    }

    static func demo() -> MonitorStore {
        let s = MonitorStore()
        s.currentLine = "Somebody told me — The Killers"
        s.hasTrack = true
        s.isPlaying = true
        s.progress = 0.42
        s.cpuPercent = 37
        s.gpuPercent = 22
        s.memPercent = 61
        s.disks = [
            DiskMonitor.Volume(
                id: "sys", name: "Macintosh HD", freePercent: 62,
                freeBytes: 620_000_000_000, totalBytes: 1_000_000_000_000, isSystem: true
            ),
            DiskMonitor.Volume(
                id: "ext", name: "External SSD", freePercent: 18,
                freeBytes: 180_000_000_000, totalBytes: 1_000_000_000_000, isSystem: false
            )
        ]
        s.netRxBytesPerSec = 1_250_000
        s.netTxBytesPerSec = 180_000
        s.batteryPercent = 78
        s.batteryCharging = true
        s.batteryPresent = true
        s.weather = WeatherSample(temperatureC: 18, code: 2, city: "Taipei")
        s.airQuality = AirQualitySample(
            aqi: 42,
            pm2_5: 12,
            pm10: 25,
            grassPollen: 5,
            treePollen: 28,
            weedPollen: 0
        )
        s.callInCall = true
        s.callAppName = "Teams"
        s.callAppProcessName = "Microsoft Teams"
        s.claudeState = ClaudeState(sessions: [
            ClaudeSession(
                id: "demo",
                project: "Iris",
                status: .tool,
                tool: "Bash",
                since: Date().addingTimeInterval(-7)
            )
        ])
        s.spectrum = (0..<AudioCapture.bandCount).map { i in
            Float(0.3 + 0.7 * abs(sin(Double(i) * 0.4)))
        }
        s.spectrumLastActiveAt = Date()
        return s
    }
}
