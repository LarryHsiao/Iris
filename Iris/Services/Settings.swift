import Foundation
import Observation

enum SpectrumPosition: String, CaseIterable, Identifiable, Hashable {
    case behind, above, below

    var id: String { rawValue }

    var label: String {
        switch self {
        case .behind: return "Behind"
        case .above: return "Above"
        case .below: return "Below"
        }
    }
}

enum Tile: String, CaseIterable, Identifiable, Hashable {
    case network, cpu, gpu, mem, disk, battery, weather, focus, calendar

    var id: String { rawValue }

    var label: String {
        switch self {
        case .network: return "Network"
        case .cpu: return "CPU"
        case .gpu: return "GPU"
        case .mem: return "Memory"
        case .disk: return "Disk"
        case .battery: return "Battery"
        case .weather: return "Weather"
        case .focus: return "Focus"
        case .calendar: return "Calendar"
        }
    }

    static let defaultOrder: [Tile] = [.network, .cpu, .gpu, .mem, .disk, .battery, .weather, .focus, .calendar]
}

@Observable
final class Settings {
    var showLyrics: Bool
    var showArtwork: Bool
    var showProgress: Bool
    var showCall: Bool
    var showSpectrum: Bool
    var spectrumPosition: SpectrumPosition
    var showCPU: Bool
    var showGPU: Bool
    var showMEM: Bool
    var showNetwork: Bool
    var showDisk: Bool
    var showBattery: Bool
    var showWeather: Bool
    var samplingInterval: Double
    var launchAtLogin: Bool
    var tileOrder: [Tile]
    var overlayWidth: Double
    var enabledExternalDiskIDs: Set<String>
    var autoHideOnFullscreen: Bool
    var showWiFiInfo: Bool
    var showFocus: Bool
    var focusMinutes: Double
    var restMinutes: Double
    var focusNotifications: Bool
    var showCalendar: Bool
    var calendarImminentMinutes: Double
    var thinMode: Bool

    var onApplied: (() -> Void)?

    static let shared: Settings = Settings.load()

    private init(
        showLyrics: Bool,
        showArtwork: Bool,
        showProgress: Bool,
        showCall: Bool,
        showSpectrum: Bool,
        spectrumPosition: SpectrumPosition,
        showCPU: Bool,
        showGPU: Bool,
        showMEM: Bool,
        showNetwork: Bool,
        showDisk: Bool,
        showBattery: Bool,
        showWeather: Bool,
        samplingInterval: Double,
        launchAtLogin: Bool,
        tileOrder: [Tile],
        overlayWidth: Double,
        enabledExternalDiskIDs: Set<String>,
        autoHideOnFullscreen: Bool,
        showWiFiInfo: Bool,
        showFocus: Bool,
        focusMinutes: Double,
        restMinutes: Double,
        focusNotifications: Bool,
        showCalendar: Bool,
        calendarImminentMinutes: Double,
        thinMode: Bool
    ) {
        self.showLyrics = showLyrics
        self.showArtwork = showArtwork
        self.showProgress = showProgress
        self.showCall = showCall
        self.showSpectrum = showSpectrum
        self.spectrumPosition = spectrumPosition
        self.showCPU = showCPU
        self.showGPU = showGPU
        self.showMEM = showMEM
        self.showNetwork = showNetwork
        self.showDisk = showDisk
        self.showBattery = showBattery
        self.showWeather = showWeather
        self.samplingInterval = samplingInterval
        self.launchAtLogin = launchAtLogin
        self.tileOrder = tileOrder
        self.overlayWidth = overlayWidth
        self.enabledExternalDiskIDs = enabledExternalDiskIDs
        self.autoHideOnFullscreen = autoHideOnFullscreen
        self.showWiFiInfo = showWiFiInfo
        self.showFocus = showFocus
        self.focusMinutes = focusMinutes
        self.restMinutes = restMinutes
        self.focusNotifications = focusNotifications
        self.showCalendar = showCalendar
        self.calendarImminentMinutes = calendarImminentMinutes
        self.thinMode = thinMode
    }

    func isVisible(_ tile: Tile) -> Bool {
        switch tile {
        case .network: return showNetwork
        case .cpu: return showCPU
        case .gpu: return showGPU
        case .mem: return showMEM
        case .disk: return showDisk
        case .battery: return showBattery
        case .weather: return showWeather
        case .focus: return showFocus
        case .calendar: return showCalendar
        }
    }

    func setVisible(_ tile: Tile, _ value: Bool) {
        switch tile {
        case .network: showNetwork = value
        case .cpu: showCPU = value
        case .gpu: showGPU = value
        case .mem: showMEM = value
        case .disk: showDisk = value
        case .battery: showBattery = value
        case .weather: showWeather = value
        case .focus: showFocus = value
        case .calendar: showCalendar = value
        }
    }

    private static let prefix = "Settings.v1."
    private enum Key {
        static let showLyrics = prefix + "showLyrics"
        static let showArtwork = prefix + "showArtwork"
        static let showProgress = prefix + "showProgress"
        static let showCall = prefix + "showCall"
        static let showSpectrum = prefix + "showSpectrum"
        static let spectrumPosition = prefix + "spectrumPosition"
        static let showCPU = prefix + "showCPU"
        static let showGPU = prefix + "showGPU"
        static let showMEM = prefix + "showMEM"
        static let showNetwork = prefix + "showNetwork"
        static let showDisk = prefix + "showDisk"
        static let showBattery = prefix + "showBattery"
        static let showWeather = prefix + "showWeather"
        static let samplingInterval = prefix + "samplingInterval"
        static let tileOrder = prefix + "tileOrder"
        static let overlayWidth = prefix + "overlayWidth"
        static let enabledExternalDiskIDs = prefix + "enabledExternalDiskIDs"
        static let autoHideOnFullscreen = prefix + "autoHideOnFullscreen"
        static let showWiFiInfo = prefix + "showWiFiInfo"
        static let showFocus = prefix + "showFocus"
        static let focusMinutes = prefix + "focusMinutes"
        static let restMinutes = prefix + "restMinutes"
        static let focusNotifications = prefix + "focusNotifications"
        static let showCalendar = prefix + "showCalendar"
        static let calendarImminentMinutes = prefix + "calendarImminentMinutes"
        static let thinMode = prefix + "thinMode"
    }

    static func load() -> Settings {
        let d = UserDefaults.standard
        return Settings(
            showLyrics: d.object(forKey: Key.showLyrics) as? Bool ?? true,
            showArtwork: d.object(forKey: Key.showArtwork) as? Bool ?? true,
            showProgress: d.object(forKey: Key.showProgress) as? Bool ?? true,
            showCall: d.object(forKey: Key.showCall) as? Bool ?? true,
            showSpectrum: d.object(forKey: Key.showSpectrum) as? Bool ?? false,
            spectrumPosition: (d.string(forKey: Key.spectrumPosition).flatMap(SpectrumPosition.init(rawValue:))) ?? .behind,
            showCPU: d.object(forKey: Key.showCPU) as? Bool ?? true,
            showGPU: d.object(forKey: Key.showGPU) as? Bool ?? true,
            showMEM: d.object(forKey: Key.showMEM) as? Bool ?? true,
            showNetwork: d.object(forKey: Key.showNetwork) as? Bool ?? true,
            showDisk: d.object(forKey: Key.showDisk) as? Bool ?? true,
            showBattery: d.object(forKey: Key.showBattery) as? Bool ?? true,
            showWeather: d.object(forKey: Key.showWeather) as? Bool ?? true,
            samplingInterval: d.object(forKey: Key.samplingInterval) as? Double ?? 2.0,
            launchAtLogin: LoginItem.isEnabled,
            tileOrder: loadTileOrder(d),
            overlayWidth: d.object(forKey: Key.overlayWidth) as? Double ?? 384,
            enabledExternalDiskIDs: Set(d.stringArray(forKey: Key.enabledExternalDiskIDs) ?? []),
            autoHideOnFullscreen: d.object(forKey: Key.autoHideOnFullscreen) as? Bool ?? true,
            showWiFiInfo: d.object(forKey: Key.showWiFiInfo) as? Bool ?? false,
            showFocus: d.object(forKey: Key.showFocus) as? Bool ?? false,
            focusMinutes: d.object(forKey: Key.focusMinutes) as? Double ?? 25,
            restMinutes: d.object(forKey: Key.restMinutes) as? Double ?? 5,
            focusNotifications: d.object(forKey: Key.focusNotifications) as? Bool ?? true,
            showCalendar: d.object(forKey: Key.showCalendar) as? Bool ?? false,
            calendarImminentMinutes: d.object(forKey: Key.calendarImminentMinutes) as? Double ?? 5,
            thinMode: d.object(forKey: Key.thinMode) as? Bool ?? false
        )
    }

    private static func loadTileOrder(_ d: UserDefaults) -> [Tile] {
        guard let raw = d.stringArray(forKey: Key.tileOrder) else { return Tile.defaultOrder }
        let parsed = raw.compactMap(Tile.init(rawValue:))
        let missing = Tile.defaultOrder.filter { !parsed.contains($0) }
        return parsed + missing
    }

    func save() {
        let d = UserDefaults.standard
        d.set(showLyrics, forKey: Key.showLyrics)
        d.set(showArtwork, forKey: Key.showArtwork)
        d.set(showProgress, forKey: Key.showProgress)
        d.set(showCall, forKey: Key.showCall)
        d.set(showSpectrum, forKey: Key.showSpectrum)
        d.set(spectrumPosition.rawValue, forKey: Key.spectrumPosition)
        d.set(showCPU, forKey: Key.showCPU)
        d.set(showGPU, forKey: Key.showGPU)
        d.set(showMEM, forKey: Key.showMEM)
        d.set(showNetwork, forKey: Key.showNetwork)
        d.set(showDisk, forKey: Key.showDisk)
        d.set(showBattery, forKey: Key.showBattery)
        d.set(showWeather, forKey: Key.showWeather)
        d.set(samplingInterval, forKey: Key.samplingInterval)
        d.set(tileOrder.map(\.rawValue), forKey: Key.tileOrder)
        d.set(overlayWidth, forKey: Key.overlayWidth)
        d.set(Array(enabledExternalDiskIDs), forKey: Key.enabledExternalDiskIDs)
        d.set(autoHideOnFullscreen, forKey: Key.autoHideOnFullscreen)
        d.set(showWiFiInfo, forKey: Key.showWiFiInfo)
        d.set(showFocus, forKey: Key.showFocus)
        d.set(focusMinutes, forKey: Key.focusMinutes)
        d.set(restMinutes, forKey: Key.restMinutes)
        d.set(focusNotifications, forKey: Key.focusNotifications)
        d.set(showCalendar, forKey: Key.showCalendar)
        d.set(calendarImminentMinutes, forKey: Key.calendarImminentMinutes)
        d.set(thinMode, forKey: Key.thinMode)
    }

    func copy() -> Settings {
        Settings(
            showLyrics: showLyrics,
            showArtwork: showArtwork,
            showProgress: showProgress,
            showCall: showCall,
            showSpectrum: showSpectrum,
            spectrumPosition: spectrumPosition,
            showCPU: showCPU,
            showGPU: showGPU,
            showMEM: showMEM,
            showNetwork: showNetwork,
            showDisk: showDisk,
            showBattery: showBattery,
            showWeather: showWeather,
            samplingInterval: samplingInterval,
            launchAtLogin: launchAtLogin,
            tileOrder: tileOrder,
            overlayWidth: overlayWidth,
            enabledExternalDiskIDs: enabledExternalDiskIDs,
            autoHideOnFullscreen: autoHideOnFullscreen,
            showWiFiInfo: showWiFiInfo,
            showFocus: showFocus,
            focusMinutes: focusMinutes,
            restMinutes: restMinutes,
            focusNotifications: focusNotifications,
            showCalendar: showCalendar,
            calendarImminentMinutes: calendarImminentMinutes,
            thinMode: thinMode
        )
    }

    func apply(from other: Settings) {
        showLyrics = other.showLyrics
        showArtwork = other.showArtwork
        showProgress = other.showProgress
        showCall = other.showCall
        showSpectrum = other.showSpectrum
        spectrumPosition = other.spectrumPosition
        showCPU = other.showCPU
        showGPU = other.showGPU
        showMEM = other.showMEM
        showNetwork = other.showNetwork
        showDisk = other.showDisk
        showBattery = other.showBattery
        showWeather = other.showWeather
        samplingInterval = other.samplingInterval
        launchAtLogin = other.launchAtLogin
        tileOrder = other.tileOrder
        overlayWidth = other.overlayWidth
        enabledExternalDiskIDs = other.enabledExternalDiskIDs
        autoHideOnFullscreen = other.autoHideOnFullscreen
        showWiFiInfo = other.showWiFiInfo
        showFocus = other.showFocus
        focusMinutes = other.focusMinutes
        restMinutes = other.restMinutes
        focusNotifications = other.focusNotifications
        showCalendar = other.showCalendar
        calendarImminentMinutes = other.calendarImminentMinutes
        thinMode = other.thinMode
    }

}
