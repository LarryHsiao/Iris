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
    var diskFreeBytes: Int64 = 0
    var gpuPercent: Double = 0
    var netRxBytesPerSec: Double = 0
    var netTxBytesPerSec: Double = 0
    var batteryPercent: Double = 0
    var batteryCharging: Bool = false
    var batteryPresent: Bool = false

    func playPause() {
        SpotifyClient.playPause()
    }
}
