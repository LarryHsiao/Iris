import CoreLocation
import CoreWLAN
import Foundation
import Network

@MainActor
final class WiFiInfoMonitor: NSObject {
    var onUpdate: ((String?, String?) -> Void)?

    private let client = CWWiFiClient.shared()
    private let locationManager = CLLocationManager()
    private var pathMonitor: NWPathMonitor?
    private var refreshTimer: Timer?
    private var running = false
    private var ssid: String?
    private var publicIP: String?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func start() {
        guard !running else { return }
        running = true
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        startPathMonitor()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshAll() }
        }
        refreshAll()
    }

    func stop() {
        guard running else { return }
        running = false
        pathMonitor?.cancel()
        pathMonitor = nil
        refreshTimer?.invalidate()
        refreshTimer = nil
        ssid = nil
        publicIP = nil
        onUpdate?(nil, nil)
    }

    private func startPathMonitor() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { _ in
            Task { @MainActor [weak self] in self?.refreshAll() }
        }
        monitor.start(queue: DispatchQueue.global(qos: .utility))
        pathMonitor = monitor
    }

    private func refreshAll() {
        ssid = client.interface()?.ssid()
        onUpdate?(ssid, publicIP)
        Task { await fetchEgressIP() }
    }

    private func fetchEgressIP() async {
        guard let url = URL(string: "https://api.ipify.org") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 6
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let value = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            await MainActor.run {
                guard self.running else { return }
                self.publicIP = (value?.isEmpty == false) ? value : self.publicIP
                self.onUpdate?(self.ssid, self.publicIP)
            }
        } catch {
            // Keep last known value on failure.
        }
    }
}

extension WiFiInfoMonitor: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in self.refreshAll() }
    }
}
