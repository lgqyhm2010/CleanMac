import CryptoKit
import Foundation

public struct DuplicateFileFinder: Sendable {
    private let snapshotReader: any FileSnapshotReading

    public init(snapshotReader: any FileSnapshotReading = SystemFileSnapshotReader()) {
        self.snapshotReader = snapshotReader
    }

    public func findDuplicates(in candidates: [CleaningCandidate]) throws -> [DuplicateFileGroup] {
        var seenPhysicalItems = Set<FileSystemIdentity>()
        let uniqueCandidates = candidates.filter { candidate in
            guard isHashableFile(candidate),
                  let expectedSnapshot = candidate.scanSnapshot,
                  expectedSnapshot.kind == .regularFile,
                  expectedSnapshot.linkCount == 1,
                  expectedSnapshot.byteCount == candidate.sizeBytes,
                  snapshotReader.snapshot(at: candidate.url) == expectedSnapshot else {
                return false
            }
            return seenPhysicalItems.insert(expectedSnapshot.identity).inserted
        }
        let candidatesBySize = Dictionary(grouping: uniqueCandidates, by: \.sizeBytes)
            .filter { sizeBytes, sameSizeCandidates in
                sizeBytes > 0 && sameSizeCandidates.count > 1
            }

        var groups: [DuplicateFileGroup] = []

        for (sizeBytes, sameSizeCandidates) in candidatesBySize {
            // Partition by a cheap prefix hash first so two same-size files that differ
            // early are never both read in full. Only prefix-colliding files (usually
            // true duplicates) pay for the whole-file hash.
            var candidatesByPrefix: [String: [CleaningCandidate]] = [:]
            for candidate in sameSizeCandidates {
                // Hashing runs inside the scan's cancellable worker; honour a pending
                // cancel between file reads so the Cancel button never appears frozen.
                try Task.checkCancellation()
                guard let prefixHash = contentHash(for: candidate.url, upTo: Self.prefixHashByteCount) else {
                    continue
                }
                candidatesByPrefix[prefixHash, default: []].append(candidate)
            }

            // Hash each file independently and skip any that cannot be read (permission
            // denied, vanished between scan and hash, transient I/O error) so one bad
            // file never aborts the entire duplicate scan.
            var candidatesByHash: [String: [CleaningCandidate]] = [:]
            for (prefixHash, samePrefixCandidates) in candidatesByPrefix where samePrefixCandidates.count > 1 {
                for candidate in samePrefixCandidates {
                    try Task.checkCancellation()
                    // At or below the prefix window the prefix already digests the whole
                    // file, so the second read would recompute the same hash.
                    let wholeFileHash = sizeBytes <= Self.prefixHashByteCount
                        ? prefixHash
                        : contentHash(for: candidate.url)
                    guard let expectedSnapshot = candidate.scanSnapshot,
                          let hash = wholeFileHash,
                          snapshotReader.snapshot(at: candidate.url) == expectedSnapshot else {
                        continue
                    }
                    candidatesByHash[hash, default: []].append(candidate)
                }
            }

            let duplicateGroups = candidatesByHash
                .filter { $0.value.count > 1 }
                .map { contentHash, duplicateCandidates in
                    DuplicateFileGroup(
                        contentHash: contentHash,
                        sizeBytes: sizeBytes,
                        candidates: duplicateCandidates.sorted {
                            $0.url.path.localizedStandardCompare($1.url.path) == .orderedAscending
                        }
                    )
                }
            groups.append(contentsOf: duplicateGroups)
        }

        return groups.sorted {
            if $0.movableReclaimableBytes == $1.movableReclaimableBytes {
                return $0.contentHash < $1.contentHash
            }
            return $0.movableReclaimableBytes > $1.movableReclaimableBytes
        }
    }

    private func isHashableFile(_ candidate: CleaningCandidate) -> Bool {
        !candidate.isDirectory && candidate.sizeBytes > 0
    }

    /// 64 KB covers headers and early metadata of most formats, enough for same-size
    /// files with different content to part ways before a whole-file read.
    private static let prefixHashByteCount = 64 * 1_024

    func contentHash(for url: URL) -> String? {
        // Memory-map when safe so two same-size multi-gigabyte files are not both pulled
        // fully into RAM just to be compared.
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            return nil
        }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func contentHash(for url: URL, upTo byteCount: Int) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: byteCount) else {
            return nil
        }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
