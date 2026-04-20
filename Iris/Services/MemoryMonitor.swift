import Foundation
import Darwin

enum MemoryMonitor {
    static func sample() -> Double {
        var stats = vm_statistics64()
        let size = MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride
        var count = mach_msg_type_number_t(size)
        let result = withUnsafeMutablePointer(to: &stats) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: size) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        let pageSize = Double(vm_kernel_page_size)
        let active = Double(stats.active_count) * pageSize
        let wired = Double(stats.wire_count) * pageSize
        let compressed = Double(stats.compressor_page_count) * pageSize
        let used = active + wired + compressed
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        guard total > 0 else { return 0 }
        return min(max(used / total, 0), 1) * 100
    }
}
