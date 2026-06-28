import Foundation

public final class DiskScanner {
    private let classifier: ScanClassifier
    private let fileManager: FileManager

    public init(
        classifier: ScanClassifier = ScanClassifier(),
        fileManager: FileManager = .default
    ) {
        self.classifier = classifier
        self.fileManager = fileManager
    }

    public func scan(roots: [URL], options: ScanOptions = ScanOptions()) throws -> ScanReport {
        var candidates: [CleaningCandidate] = []
        var scannedFileCount = 0
        var skippedFileCount = 0
        let activeClassifier = options.largeFileThresholdBytes.map {
            ScanClassifier(largeFileThresholdBytes: $0)
        } ?? classifier

        let keys: [URLResourceKey] = [
            .contentModificationDateKey,
            .fileSizeKey,
            .isDirectoryKey,
            .isHiddenKey,
            .isRegularFileKey
        ]

        for root in roots {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: keys,
                options: [.skipsPackageDescendants],
                errorHandler: { _, _ in
                    skippedFileCount += 1
                    return true
                }
            ) else {
                skippedFileCount += 1
                continue
            }

            for case let url as URL in enumerator {
                let values: URLResourceValues
                do {
                    values = try url.resourceValues(forKeys: Set(keys))
                } catch {
                    skippedFileCount += 1
                    continue
                }

                if values.isDirectory == true {
                    if !options.includeHiddenFiles, isHidden(url: url, values: values) {
                        enumerator.skipDescendants()
                    }
                    continue
                }

                guard values.isRegularFile == true else {
                    continue
                }

                scannedFileCount += 1

                guard options.includeHiddenFiles || !isHidden(url: url, values: values) else {
                    skippedFileCount += 1
                    continue
                }

                let sizeBytes = Int64(values.fileSize ?? 0)
                guard sizeBytes >= options.minimumFileSizeBytes else {
                    skippedFileCount += 1
                    continue
                }

                let classification = activeClassifier.classify(
                    url: url,
                    sizeBytes: sizeBytes,
                    isDirectory: false
                )

                candidates.append(
                    CleaningCandidate(
                        url: url,
                        sizeBytes: sizeBytes,
                        modifiedAt: values.contentModificationDate,
                        category: classification.category,
                        risk: classification.risk,
                        reasons: classification.reasons,
                        isDirectory: false
                    )
                )
            }
        }

        candidates.sort {
            if $0.sizeBytes == $1.sizeBytes {
                return $0.url.path.localizedStandardCompare($1.url.path) == .orderedAscending
            }
            return $0.sizeBytes > $1.sizeBytes
        }

        return ScanReport(
            candidates: candidates,
            totalBytes: candidates.reduce(0) { $0 + $1.sizeBytes },
            scannedFileCount: scannedFileCount,
            skippedFileCount: skippedFileCount
        )
    }

    private func isHidden(url: URL, values: URLResourceValues) -> Bool {
        if values.isHidden == true {
            return true
        }
        return url.lastPathComponent.hasPrefix(".")
    }
}
