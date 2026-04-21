import Foundation
import IOKit

enum GPUMonitor {
    static func sample() -> Double {
        var iterator: io_iterator_t = 0
        let match = IOServiceMatching("IOAccelerator")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, match, &iterator) == KERN_SUCCESS
        else { return 0 }
        defer { IOObjectRelease(iterator) }

        var best: Double = 0
        while true {
            let service = IOIteratorNext(iterator)
            if service == 0 { break }
            defer { IOObjectRelease(service) }
            if let util = utilization(of: service), util > best { best = util }
        }
        return best
    }

    private static func utilization(of service: io_registry_entry_t) -> Double? {
        var unmanaged: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &unmanaged, kCFAllocatorDefault, 0)
                == KERN_SUCCESS,
              let props = unmanaged?.takeRetainedValue() as? [String: Any],
              let perf = props["PerformanceStatistics"] as? [String: Any],
              let util = perf["Device Utilization %"] as? NSNumber
        else { return nil }
        return util.doubleValue
    }
}
