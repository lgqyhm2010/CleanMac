import Foundation

public struct AppUninstaller {
    private let fileManager: FileManager
    private let safetyRuleEngine: SafetyRuleEngine
    private let snapshotReader: any FileSnapshotReading

    public init(
        fileManager: FileManager = .default,
        safetyRuleEngine: SafetyRuleEngine = SafetyRuleEngine(),
        snapshotReader: any FileSnapshotReading = SystemFileSnapshotReader()
    ) {
        self.fileManager = fileManager
        self.safetyRuleEngine = safetyRuleEngine
        self.snapshotReader = snapshotReader
    }

    public func scan(appRoots: [URL]) throws -> [AppUninstallPlan] {
        var seenPaths = Set<String>()
        let appBundles = try appRoots
            .flatMap(findAppBundles(in:))
            .filter { seenPaths.insert($0.standardizedFileURL.path).inserted }
        let plans = try appBundles.compactMap { appBundle in
            try makePlan(appBundle: appBundle)
        }
        return plans.sorted {
            let nameOrder = $0.appName.localizedStandardCompare($1.appName)
            if nameOrder == .orderedSame {
                return $0.appCandidate.url.path.localizedStandardCompare($1.appCandidate.url.path) == .orderedAscending
            }
            return nameOrder == .orderedAscending
        }
    }

    private func findAppBundles(in root: URL) throws -> [URL] {
        // Always called from a detached task; checking on every recursion step keeps
        // cancellation responsive across large application folders.
        try Task.checkCancellation()

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              !isSymbolicLink(root) else {
            return []
        }

        if root.pathExtension.localizedCaseInsensitiveCompare("app") == .orderedSame {
            guard appMetadata(appBundle: root) == nil else {
                return [root]
            }
        }

        var appBundles: [URL] = []
        let children = (try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        for rawChild in children {
            let child = root.appending(path: rawChild.lastPathComponent, directoryHint: .checkFileSystem)
            var childIsDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: child.path, isDirectory: &childIsDirectory),
                  childIsDirectory.boolValue,
                  !isSymbolicLink(child) else {
                continue
            }

            if child.pathExtension.localizedCaseInsensitiveCompare("app") == .orderedSame {
                if appMetadata(appBundle: child) != nil {
                    appBundles.append(child)
                } else {
                    appBundles.append(contentsOf: try findAppBundles(in: child))
                }
            } else {
                appBundles.append(contentsOf: try findAppBundles(in: child))
            }
        }

        return appBundles
    }

    private func makePlan(appBundle: URL) throws -> AppUninstallPlan? {
        guard let metadata = appMetadata(appBundle: appBundle) else {
            return nil
        }

        guard let appCandidate = try makeCandidate(
            url: appBundle,
            category: .application,
            reasons: ["Application bundle for \(metadata.bundleIdentifier)"],
            isDirectory: true
        ) else {
            return nil
        }

        return AppUninstallPlan(
            appName: metadata.appName,
            bundleIdentifier: metadata.bundleIdentifier,
            appCandidate: appCandidate
        )
    }

    private func appMetadata(appBundle: URL) -> AppMetadata? {
        let infoURL = appBundle.appending(path: "Contents/Info.plist")
        guard let data = try? Data(contentsOf: infoURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let rawBundleIdentifier = plist["CFBundleIdentifier"] as? String,
              let bundleIdentifier = validatedBundleIdentifier(rawBundleIdentifier) else {
            return nil
        }

        let appName = (plist["CFBundleDisplayName"] as? String)
            ?? (plist["CFBundleName"] as? String)
            ?? appBundle.deletingPathExtension().lastPathComponent

        return AppMetadata(appName: appName, bundleIdentifier: bundleIdentifier)
    }

    private func validatedBundleIdentifier(_ rawValue: String) -> String? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 255 else { return nil }

        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-"))
        guard value.unicodeScalars.allSatisfy(allowedCharacters.contains) else { return nil }

        let components = value.split(separator: ".", omittingEmptySubsequences: false)
        guard components.count >= 2, components.allSatisfy({ !$0.isEmpty }) else { return nil }
        return value
    }

    private func isSymbolicLink(_ url: URL) -> Bool {
        guard let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey]) else {
            return true
        }
        return values.isSymbolicLink == true
    }

    private func makeCandidate(
        url: URL,
        category: CandidateCategory,
        reasons: [String],
        isDirectory: Bool
    ) throws -> CleaningCandidate? {
        let stableURL = stableCandidateURL(url)
        guard let snapshot = snapshotReader.snapshot(at: stableURL),
              snapshot.kind == .directory else {
            return nil
        }
        let values = try? stableURL.resourceValues(forKeys: [.contentModificationDateKey])
        let sizeBytes = try itemSize(stableURL)
        let safety = safetyRuleEngine.evaluate(
            url: stableURL,
            category: category,
            risk: .reviewRecommended,
            reasons: reasons,
            isDirectory: isDirectory
        )

        return CleaningCandidate(
            url: stableURL,
            sizeBytes: sizeBytes,
            modifiedAt: values?.contentModificationDate,
            category: category,
            risk: .reviewRecommended,
            reasons: reasons,
            isDirectory: isDirectory,
            protection: safety.protection,
            ruleMatches: safety.ruleMatches,
            userVisibleRules: safety.userVisibleRules,
            scanSnapshot: snapshot
        )
    }

    private func stableCandidateURL(_ url: URL) -> URL {
        let path = url.path
        guard path.count > 1, path.hasSuffix("/") else {
            return url
        }
        return URL(fileURLWithPath: String(path.dropLast()), isDirectory: false)
    }

    private func itemSize(_ url: URL) throws -> Int64 {
        if isDirectory(url) {
            // Count hidden files too — app bundles and support folders routinely store
            // dot-prefixed databases and resources, so skipping them undercounts the size
            // shown to the user.
            guard let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
                options: [],
                errorHandler: { _, _ in true }
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

        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]) else {
            return 0
        }
        return Int64(values.fileSize ?? 0)
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}

private struct AppMetadata {
    let appName: String
    let bundleIdentifier: String
}
