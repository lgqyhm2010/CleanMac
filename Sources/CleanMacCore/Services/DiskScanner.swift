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
            .isPackageKey,
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
                    if isPackage(url: url, values: values) {
                        // A file-system package (.app, .photoslibrary, .bundle, …) is one
                        // logical item. Report it as a single sized candidate rather than
                        // skipping it, and do not descend into or list its internals.
                        enumerator.skipDescendants()

                        guard options.includeHiddenFiles || !isHidden(url: url, values: values) else {
                            skippedFileCount += 1
                            continue
                        }

                        scannedFileCount += 1
                        let sizeBytes = packageSize(at: url)
                        guard sizeBytes >= options.minimumFileSizeBytes else {
                            skippedFileCount += 1
                            continue
                        }

                        let classification = activeClassifier.classify(
                            url: url,
                            sizeBytes: sizeBytes,
                            isDirectory: true
                        )

                        candidates.append(
                            CleaningCandidate(
                                url: url,
                                sizeBytes: sizeBytes,
                                modifiedAt: values.contentModificationDate,
                                category: classification.category,
                                risk: classification.risk,
                                reasons: classification.reasons,
                                isDirectory: true,
                                protection: classification.protection,
                                ruleMatches: classification.ruleMatches,
                                userVisibleRules: classification.userVisibleRules
                            )
                        )
                        continue
                    }

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
                        isDirectory: false,
                        protection: classification.protection,
                        ruleMatches: classification.ruleMatches,
                        userVisibleRules: classification.userVisibleRules
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

        let duplicateGroups = try DuplicateFileFinder().findDuplicates(in: candidates)

        return ScanReport(
            candidates: candidates,
            duplicateGroups: duplicateGroups,
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

    private func isPackage(url: URL, values: URLResourceValues) -> Bool {
        if values.isPackage == true {
            return true
        }
        // Fall back to well-known package extensions in case LaunchServices has not
        // registered the bundle type (e.g. a copied app on an external volume).
        let packageExtensions: Set<String> = [
            "app", "bundle", "framework", "photoslibrary", "rtfd",
            "imovielibrary", "tvlibrary", "aplibrary", "xcdatamodeld"
        ]
        return packageExtensions.contains(url.pathExtension.lowercased())
    }

    private func packageSize(at url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: []
        ) else {
            return 0
        }

        var total: Int64 = 0
        for case let child as URL in enumerator {
            guard let values = try? child.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true else {
                continue
            }
            total += Int64(values.fileSize ?? 0)
        }
        return total
    }
}
