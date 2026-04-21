import Foundation
import Darwin

@MainActor
final class NetworkMonitor {
    struct Throughput {
        let rxBytesPerSec: Double
        let txBytesPerSec: Double
    }

    private var previous: (rx: UInt64, tx: UInt64, at: Date)?

    func sample() -> Throughput {
        let counters = readCounters()
        let now = Date()
        defer { previous = (counters.rx, counters.tx, now) }
        guard let prev = previous else { return Throughput(rxBytesPerSec: 0, txBytesPerSec: 0) }
        let dt = now.timeIntervalSince(prev.at)
        guard dt > 0 else { return Throughput(rxBytesPerSec: 0, txBytesPerSec: 0) }
        let rxRate = Double(counters.rx &- prev.rx) / dt
        let txRate = Double(counters.tx &- prev.tx) / dt
        return Throughput(rxBytesPerSec: max(rxRate, 0), txBytesPerSec: max(txRate, 0))
    }

    static func format(bytesPerSec: Double) -> String {
        let kb = bytesPerSec / 1024
        if kb < 1 { return "0K" }
        if kb < 1024 { return String(format: "%.0fK", kb) }
        let mb = kb / 1024
        if mb < 10 { return String(format: "%.1fM", mb) }
        return String(format: "%.0fM", mb)
    }

    private func readCounters() -> (rx: UInt64, tx: UInt64) {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var len = 0
        guard sysctl(&mib, 6, nil, &len, nil, 0) == 0, len > 0 else { return (0, 0) }
        var buf = [UInt8](repeating: 0, count: len)
        let ok = buf.withUnsafeMutableBufferPointer { ptr -> Bool in
            sysctl(&mib, 6, ptr.baseAddress, &len, nil, 0) == 0
        }
        guard ok else { return (0, 0) }

        var rx: UInt64 = 0
        var tx: UInt64 = 0
        buf.withUnsafeBytes { raw in
            guard let base = raw.baseAddress else { return }
            var offset = 0
            while offset < len {
                let hdrPtr = base.advanced(by: offset).assumingMemoryBound(to: if_msghdr.self)
                let hdr = hdrPtr.pointee
                let msgLen = Int(hdr.ifm_msglen)
                if msgLen == 0 { break }
                if Int32(hdr.ifm_type) == RTM_IFINFO2 {
                    let msg = base.advanced(by: offset)
                        .assumingMemoryBound(to: if_msghdr2.self).pointee
                    if (Int32(msg.ifm_flags) & IFF_LOOPBACK) == 0 {
                        rx &+= UInt64(msg.ifm_data.ifi_ibytes)
                        tx &+= UInt64(msg.ifm_data.ifi_obytes)
                    }
                }
                offset += msgLen
            }
        }
        return (rx, tx)
    }
}
