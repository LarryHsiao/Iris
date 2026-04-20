import Foundation
import Darwin

@MainActor
final class CPUMonitor {
    private var previous: host_cpu_load_info?

    func sample() -> Double {
        var info = host_cpu_load_info()
        let size = MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride
        var count = mach_msg_type_number_t(size)

        let result = withUnsafeMutablePointer(to: &info) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: size) { intPtr in
                host_statistics64(mach_host_self(), HOST_CPU_LOAD_INFO, intPtr, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }

        defer { previous = info }
        guard let prev = previous else { return 0 }

        let user   = Double(info.cpu_ticks.0) - Double(prev.cpu_ticks.0)
        let system = Double(info.cpu_ticks.1) - Double(prev.cpu_ticks.1)
        let idle   = Double(info.cpu_ticks.2) - Double(prev.cpu_ticks.2)
        let nice   = Double(info.cpu_ticks.3) - Double(prev.cpu_ticks.3)

        let active = user + system + nice
        let total = active + idle
        guard total > 0 else { return 0 }
        return (active / total) * 100
    }
}
