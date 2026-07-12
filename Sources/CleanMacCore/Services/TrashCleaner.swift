import Foundation

public protocol FileTrashing {
    func trashItem(at url: URL) throws
}

extension FileManager: FileTrashing {
    public func trashItem(at url: URL) throws {
        var resultingURL: NSURL?
        try trashItem(at: url, resultingItemURL: &resultingURL)
    }
}

public struct TrashCleaner {
    private let trasher: FileTrashing
    private let snapshotReader: any FileSnapshotReading

    public init(
        trasher: FileTrashing = FileManager.default,
        snapshotReader: any FileSnapshotReading = SystemFileSnapshotReader()
    ) {
        self.trasher = trasher
        self.snapshotReader = snapshotReader
    }

    public func clean(_ candidates: [CleaningCandidate]) throws -> CleanupResult {
        try clean(candidates.map { CleanupRequest(candidate: $0) })
    }

    public func clean(_ requests: [CleanupRequest]) throws -> CleanupResult {
        var cleanedCount = 0
        var reclaimedBytes: Int64 = 0
        var failures: [CleanupFailure] = []
        var skipped: [CleanupSkippedItem] = []

        for request in requests {
            let candidate = request.candidate
            guard candidate.protection != .blocked else {
                let ruleSummary = candidate.userVisibleRules.first ?? "Protected by safety rules"
                skipped.append(CleanupSkippedItem(
                    url: candidate.url,
                    message: "Protected item skipped: \(ruleSummary)",
                    reason: .protected
                ))
                continue
            }

            guard let expectedSnapshot = candidate.scanSnapshot else {
                skipped.append(CleanupSkippedItem(
                    url: candidate.url,
                    message: "Item skipped because its scan identity is unavailable.",
                    reason: .snapshotUnavailable
                ))
                continue
            }

            guard expectedSnapshot.kind == .regularFile || expectedSnapshot.kind == .directory else {
                skipped.append(CleanupSkippedItem(
                    url: candidate.url,
                    message: "Item skipped because its filesystem type is unsupported.",
                    reason: .unsupportedFileType
                ))
                continue
            }

            guard snapshotReader.snapshot(at: candidate.url) == expectedSnapshot else {
                skipped.append(CleanupSkippedItem(
                    url: candidate.url,
                    message: "Item skipped because it changed since the scan.",
                    reason: .changedSinceScan
                ))
                continue
            }

            if let expectedContentHash = request.expectedContentHash {
                let currentContentHash = DuplicateFileFinder(snapshotReader: snapshotReader)
                    .contentHash(for: candidate.url)
                guard currentContentHash == expectedContentHash else {
                    skipped.append(CleanupSkippedItem(
                        url: candidate.url,
                        message: "Item skipped because its content changed since duplicate analysis.",
                        reason: .contentChanged
                    ))
                    continue
                }
            }

            // Hashing can take time for large duplicates. Recheck metadata once more at
            // the last possible point before handing the path to FileManager.
            guard snapshotReader.snapshot(at: candidate.url) == expectedSnapshot else {
                skipped.append(CleanupSkippedItem(
                    url: candidate.url,
                    message: "Item skipped because it changed since the scan.",
                    reason: .changedSinceScan
                ))
                continue
            }

            do {
                try trasher.trashItem(at: candidate.url)
                cleanedCount += 1
                reclaimedBytes += candidate.sizeBytes
            } catch {
                failures.append(CleanupFailure(url: candidate.url, message: error.localizedDescription))
            }
        }

        return CleanupResult(
            cleanedCount: cleanedCount,
            reclaimedBytes: reclaimedBytes,
            failures: failures,
            skipped: skipped
        )
    }
}
