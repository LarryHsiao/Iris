import Foundation

enum DiskMonitor {
    struct Volume: Identifiable, Equatable {
        let id: String
        let name: String
        let freePercent: Double
        let isSystem: Bool
    }

    static func detectAll() -> [Volume] {
        let keys: [URLResourceKey] = [
            .volumeLocalizedNameKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeTotalCapacityKey,
            .volumeUUIDStringKey,
            .volumeIsRootFileSystemKey,
            .volumeIsBrowsableKey,
            .volumeIsInternalKey
        ]
        guard let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) else { return [] }

        var out: [Volume] = []
        for url in urls {
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.volumeIsBrowsable == true,
                  let total = values.volumeTotalCapacity, total > 0 else { continue }
            let freeBytes = values.volumeAvailableCapacityForImportantUsage ?? 0
            let percent = Double(freeBytes) / Double(total) * 100
            let isSystem = values.volumeIsRootFileSystem ?? false
            let id = values.volumeUUIDString ?? url.path
            let name = values.volumeLocalizedName
                ?? (url.path as NSString).lastPathComponent
            out.append(Volume(
                id: id,
                name: name,
                freePercent: max(0, min(100, percent)),
                isSystem: isSystem
            ))
        }
        return out.sorted { lhs, rhs in
            if lhs.isSystem != rhs.isSystem { return lhs.isSystem }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    static func sample(enabledExternalIDs: Set<String>) -> [Volume] {
        detectAll().filter { $0.isSystem || enabledExternalIDs.contains($0.id) }
    }
}
