import Foundation
import Observation

@Observable
final class MonitorStore {
    var currentLine: String = "—"
    var cpuPercent: Double = 0
    var isPlaying: Bool = false
    var artworkURL: URL?
    var progress: Double = 0
    var cpuHistory: [Double] = []

    func recordCPU(_ value: Double) {
        cpuPercent = value
        cpuHistory.append(value)
        if cpuHistory.count > 30 {
            cpuHistory.removeFirst(cpuHistory.count - 30)
        }
    }
}
