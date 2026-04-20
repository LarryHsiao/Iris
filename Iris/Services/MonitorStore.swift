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

    func playPause() {
        SpotifyClient.playPause()
    }
}
