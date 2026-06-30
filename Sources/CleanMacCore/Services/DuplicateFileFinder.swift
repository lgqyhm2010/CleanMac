import CryptoKit
import Foundation

public struct DuplicateFileFinder: Sendable {
    public init() {}

    public func findDuplicates(in candidates: [CleaningCandidate]) throws -> [DuplicateFileGroup] {
        let candidatesBySize = Dictionary(grouping: candidates.filter(isHashableFile), by: \.sizeBytes)
            .filter { sizeBytes, sameSizeCandidates in
                sizeBytes > 0 && sameSizeCandidates.count > 1
            }

        var groups: [DuplicateFileGroup] = []

        for (sizeBytes, sameSizeCandidates) in candidatesBySize {
            // Hash each file independently and skip any that cannot be read (permission
            // denied, vanished between scan and hash, transient I/O error) so one bad
            // file never aborts the entire duplicate scan.
            var candidatesByHash: [String: [CleaningCandidate]] = [:]
            for candidate in sameSizeCandidates {
                guard let hash = contentHash(for: candidate.url) else { continue }
                candidatesByHash[hash, default: []].append(candidate)
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

    private func contentHash(for url: URL) -> String? {
        // Memory-map when safe so two same-size multi-gigabyte files are not both pulled
        // fully into RAM just to be compared.
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            return nil
        }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
