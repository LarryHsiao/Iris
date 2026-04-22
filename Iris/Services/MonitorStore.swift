import Foundation
import Observation

@Observable
final class MonitorStore {
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
    var callInCall: Bool = false
    var callAppName: String?

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
            DiskMonitor.Volume(id: "sys", name: "Macintosh HD", freePercent: 62, isSystem: true),
            DiskMonitor.Volume(id: "ext", name: "External SSD", freePercent: 18, isSystem: false)
        ]
        s.netRxBytesPerSec = 1_250_000
        s.netTxBytesPerSec = 180_000
        s.batteryPercent = 78
        s.batteryCharging = true
        s.batteryPresent = true
        s.callInCall = true
        s.callAppName = "Teams"
        return s
    }
}
