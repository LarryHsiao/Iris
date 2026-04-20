import Foundation
import Observation

@Observable
final class MonitorStore {
    var currentLine: String = "—"
    var cpuPercent: Double = 0
    var isPlaying: Bool = false
    var artworkURL: URL?
}
