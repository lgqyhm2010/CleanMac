import Foundation

public struct StorageVolumeSnapshot: Equatable, Sendable {
    public let name: String
    public let totalCapacityBytes: Int64
    public let availableCapacityBytes: Int64

    public var usedCapacityBytes: Int64 {
        max(0, totalCapacityBytes - availableCapacityBytes)
    }

    public init(name: String, totalCapacityBytes: Int64, availableCapacityBytes: Int64) {
        self.name = name
        self.totalCapacityBytes = totalCapacityBytes
        self.availableCapacityBytes = availableCapacityBytes
    }
}

public struct StorageVolumeReporter: Sendable {
    public init() {}

    public func snapshot(for url: URL) -> StorageVolumeSnapshot? {
        let keys: Set<URLResourceKey> = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ]

        guard
            let values = try? url.resourceValues(forKeys: keys),
            let totalCapacity = values.volumeTotalCapacity,
            totalCapacity > 0
        else {
            return nil
        }

        let availableCapacity = values.volumeAvailableCapacityForImportantUsage
            ?? values.volumeAvailableCapacity.map(Int64.init)
            ?? 0
        let name = values.volumeName?.trimmingCharacters(in: .whitespacesAndNewlines)

        return StorageVolumeSnapshot(
            name: name?.isEmpty == false ? name! : fallbackName(for: url),
            totalCapacityBytes: Int64(totalCapacity),
            availableCapacityBytes: max(0, min(Int64(totalCapacity), availableCapacity))
        )
    }

    public func snapshot(for roots: [URL], fallback fallbackURL: URL) -> StorageVolumeSnapshot? {
        for root in roots {
            if let snapshot = snapshot(for: root) {
                return snapshot
            }
        }
        return snapshot(for: fallbackURL)
    }

    private func fallbackName(for url: URL) -> String {
        let standardized = url.standardizedFileURL
        if standardized.path == "/" {
            return "/"
        }

        let lastPathComponent = standardized.lastPathComponent
        return lastPathComponent.isEmpty ? standardized.path : lastPathComponent
    }
}
