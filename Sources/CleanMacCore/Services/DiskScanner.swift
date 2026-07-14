import Foundation

public final class DiskScanner {
    private let classifier: ScanClassifier
    private let fileManager: FileManager
    private let snapshotReader: any FileSnapshotReading

    public init(
        classifier: ScanClassifier = ScanClassifier(),
        fileManager: FileManager = .default,
        snapshotReader: any FileSnapshotReading = SystemFileSnapshotReader()
    ) {
        self.classifier = classifier
        self.fileManager = fileManager
        self.snapshotReader = snapshotReader
    }

    public func scan(
        roots: [URL],
        options: ScanOptions = ScanOptions(),
        onProgress: (@Sendable (Int) -> Void)? = nil
    ) throws -> ScanReport {
        var candidates: [CleaningCandidate] = []
        var scannedFileCount = 0
        var skippedFileCount = 0
        var seenPhysicalItems = Set<FileSystemIdentity>()
        let activeClassifier = options.largeFileThresholdBytes.map {
            classifier.replacingLargeFileThreshold(with: $0)
        } ?? classifier

        let keys: [URLResourceKey] = [
            .contentModificationDateKey,
            .fileSizeKey,
            .isDirectoryKey,
            .isHiddenKey,
            .isPackageKey,
            .isRegularFileKey
        ]

        // Reports roughly every 256 scanned files so UI progress updates stay cheap.
        func reportProgressIfNeeded() {
            if scannedFileCount.isMultiple(of: 256) {
                onProgress?(scannedFileCount)
            }
        }

        for root in nonOverlappingRoots(roots) {
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
                // Always called from a detached task; checking each iteration keeps
                // cancellation latency low without measurable overhead.
                try Task.checkCancellation()

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

                        guard let snapshot = snapshotReader.snapshot(at: url),
                              snapshot.kind == .directory,
                              seenPhysicalItems.insert(snapshot.identity).inserted else {
                            skippedFileCount += 1
                            continue
                        }

                        scannedFileCount += 1
                        reportProgressIfNeeded()
                        let sizeBytes = try packageSize(at: url)
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
                                userVisibleRules: classification.userVisibleRules,
                                scanSnapshot: snapshot
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

                guard let snapshot = snapshotReader.snapshot(at: url),
                      snapshot.kind == .regularFile,
                      seenPhysicalItems.insert(snapshot.identity).inserted else {
                    skippedFileCount += 1
                    continue
                }

                scannedFileCount += 1
                reportProgressIfNeeded()

                guard options.includeHiddenFiles || !isHidden(url: url, values: values) else {
                    skippedFileCount += 1
                    continue
                }

                let sizeBytes = snapshot.byteCount
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
                        userVisibleRules: classification.userVisibleRules,
                        scanSnapshot: snapshot
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

    private func nonOverlappingRoots(_ roots: [URL]) -> [URL] {
        let canonicalRoots = Set(roots.map {
            $0.standardizedFileURL.resolvingSymlinksInPath()
        }).sorted {
            if $0.pathComponents.count == $1.pathComponents.count {
                return $0.path.localizedStandardCompare($1.path) == .orderedAscending
            }
            return $0.pathComponents.count < $1.pathComponents.count
        }

        return canonicalRoots.reduce(into: []) { accepted, candidate in
            guard !accepted.contains(where: { isDescendantOrEqual(candidate, of: $0) }) else {
                return
            }
            accepted.append(candidate)
        }
    }

    private func isDescendantOrEqual(_ candidate: URL, of root: URL) -> Bool {
        let candidatePath = candidate.standardizedFileURL.path
        let rootPath = root.standardizedFileURL.path
        let descendantPrefix = rootPath == "/" ? "/" : rootPath + "/"
        return candidatePath == rootPath || candidatePath.hasPrefix(descendantPrefix)
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

    private func packageSize(at url: URL) throws -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: []
        ) else {
            return 0
        }

        var total: Int64 = 0
        for case let child as URL in enumerator {
            try Task.checkCancellation()
            guard let values = try? child.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true else {
                continue
            }
            total += Int64(values.fileSize ?? 0)
        }
        return total
    }
}
