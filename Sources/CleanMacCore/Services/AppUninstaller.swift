import Foundation

public struct AppUninstaller {
    private let fileManager: FileManager
    private let safetyRuleEngine: SafetyRuleEngine

    public init(
        fileManager: FileManager = .default,
        safetyRuleEngine: SafetyRuleEngine = SafetyRuleEngine()
    ) {
        self.fileManager = fileManager
        self.safetyRuleEngine = safetyRuleEngine
    }

    public func scan(appRoots: [URL], userLibrary: URL) throws -> [AppUninstallPlan] {
        let appBundles = try appRoots.flatMap(findAppBundles(in:))
        let plans = try appBundles.compactMap { appBundle in
            try makePlan(appBundle: appBundle, userLibrary: userLibrary)
        }
        return plans.sorted {
            $0.appName.localizedStandardCompare($1.appName) == .orderedAscending
        }
    }

    private func findAppBundles(in root: URL) throws -> [URL] {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return []
        }

        if root.pathExtension.localizedCaseInsensitiveCompare("app") == .orderedSame {
            return [root]
        }

        var appBundles: [URL] = []
        let children = try fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        for rawChild in children {
            let child = root.appending(path: rawChild.lastPathComponent, directoryHint: .checkFileSystem)
            let values = try child.resourceValues(forKeys: [.isDirectoryKey])
            guard values.isDirectory == true else { continue }

            if child.pathExtension.localizedCaseInsensitiveCompare("app") == .orderedSame {
                appBundles.append(child)
            } else {
                appBundles.append(contentsOf: try findAppBundles(in: child))
            }
        }

        return appBundles
    }

    private func makePlan(appBundle: URL, userLibrary: URL) throws -> AppUninstallPlan? {
        guard let metadata = try appMetadata(appBundle: appBundle) else {
            return nil
        }

        let appCandidate = try makeCandidate(
            url: appBundle,
            category: .application,
            reasons: ["Application bundle for \(metadata.bundleIdentifier)"],
            isDirectory: true
        )

        let supportCandidates = try supportURLs(
            bundleIdentifier: metadata.bundleIdentifier,
            userLibrary: userLibrary
        )
        .map {
            try makeCandidate(
                url: $0,
                category: .applicationSupport,
                reasons: ["App uninstall support item for \(metadata.bundleIdentifier)"],
                isDirectory: isDirectory($0)
            )
        }

        return AppUninstallPlan(
            appName: metadata.appName,
            bundleIdentifier: metadata.bundleIdentifier,
            appCandidate: appCandidate,
            supportCandidates: supportCandidates.sorted {
                $0.url.path.localizedStandardCompare($1.url.path) == .orderedAscending
            }
        )
    }

    private func appMetadata(appBundle: URL) throws -> AppMetadata? {
        let infoURL = appBundle.appending(path: "Contents/Info.plist")
        guard let data = try? Data(contentsOf: infoURL),
              let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let bundleIdentifier = plist["CFBundleIdentifier"] as? String,
              !bundleIdentifier.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let appName = (plist["CFBundleDisplayName"] as? String)
            ?? (plist["CFBundleName"] as? String)
            ?? appBundle.deletingPathExtension().lastPathComponent

        return AppMetadata(appName: appName, bundleIdentifier: bundleIdentifier)
    }

    private func supportURLs(bundleIdentifier: String, userLibrary: URL) throws -> [URL] {
        // Match support data only by the reverse-DNS bundle identifier. The display name
        // is frequently a generic vendor name (e.g. "Google") shared by many apps, so
        // matching `Application Support/<appName>` would claim folders that belong to
        // unrelated apps.
        let directMatches = [
            userLibrary.appending(path: "Application Support/\(bundleIdentifier)"),
            userLibrary.appending(path: "Caches/\(bundleIdentifier)"),
            userLibrary.appending(path: "Preferences/\(bundleIdentifier).plist"),
            userLibrary.appending(path: "Saved Application State/\(bundleIdentifier).savedState"),
            userLibrary.appending(path: "Logs/\(bundleIdentifier)"),
            userLibrary.appending(path: "Containers/\(bundleIdentifier)"),
            userLibrary.appending(path: "Group Containers/\(bundleIdentifier)")
        ]

        var matches: [URL] = []
        for url in directMatches where fileManager.fileExists(atPath: url.path) {
            matches.append(contentsOf: try leafURLs(for: url))
        }

        return Array(Set(matches.map { $0.standardizedFileURL })).sorted {
            $0.path.localizedStandardCompare($1.path) == .orderedAscending
        }
    }

    private func leafURLs(for url: URL) throws -> [URL] {
        guard isDirectory(url) else { return [url] }

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return [url]
        }

        var leafURLs: [URL] = []
        for case let child as URL in enumerator {
            let values = try child.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
            if values.isRegularFile == true {
                leafURLs.append(child)
            }
        }

        return leafURLs.isEmpty ? [url] : leafURLs
    }

    private func makeCandidate(
        url: URL,
        category: CandidateCategory,
        reasons: [String],
        isDirectory: Bool
    ) throws -> CleaningCandidate {
        let stableURL = stableCandidateURL(url)
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
            userVisibleRules: safety.userVisibleRules
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
                options: []
            ) else {
                return 0
            }

            var total: Int64 = 0
            for case let child as URL in enumerator {
                let values = try child.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
                guard values.isRegularFile == true else { continue }
                total += Int64(values.fileSize ?? 0)
            }
            return total
        }

        let values = try url.resourceValues(forKeys: [.fileSizeKey])
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
