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

    public init(trasher: FileTrashing = FileManager.default) {
        self.trasher = trasher
    }

    public func clean(_ candidates: [CleaningCandidate]) throws -> CleanupResult {
        var cleanedCount = 0
        var reclaimedBytes: Int64 = 0
        var failures: [CleanupFailure] = []

        for candidate in candidates {
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
            failures: failures
        )
    }
}
