import Foundation
import IOKit.ps

enum BatteryMonitor {
    struct State {
        let percent: Double
        let isCharging: Bool
        let isPresent: Bool
    }

    static func sample() -> State {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef]
        else { return State(percent: 0, isCharging: false, isPresent: false) }

        for src in sources {
            guard let info = IOPSGetPowerSourceDescription(blob, src)?.takeUnretainedValue()
                    as? [String: Any],
                  let type = info[kIOPSTypeKey] as? String,
                  type == kIOPSInternalBatteryType
            else { continue }
            let current = info[kIOPSCurrentCapacityKey] as? Int ?? 0
            let maximum = info[kIOPSMaxCapacityKey] as? Int ?? 100
            let charging = info[kIOPSIsChargingKey] as? Bool ?? false
            let pct = maximum > 0 ? Double(current) / Double(maximum) * 100 : 0
            return State(percent: pct, isCharging: charging, isPresent: true)
        }
        return State(percent: 0, isCharging: false, isPresent: false)
    }
}
