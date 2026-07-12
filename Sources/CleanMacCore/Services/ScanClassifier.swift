import Foundation

public struct ScanClassifier: Sendable {
    private let largeFileThresholdBytes: Int64
    private let safetyRuleEngine: SafetyRuleEngine
    private let homeDirectory: URL
    private let temporaryDirectory: URL

    public init(
        largeFileThresholdBytes: Int64 = 500 * 1_024 * 1_024,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        temporaryDirectory: URL = FileManager.default.temporaryDirectory
    ) {
        self.largeFileThresholdBytes = largeFileThresholdBytes
        self.safetyRuleEngine = SafetyRuleEngine()
        self.homeDirectory = homeDirectory
        self.temporaryDirectory = temporaryDirectory
    }

    func replacingLargeFileThreshold(with threshold: Int64) -> ScanClassifier {
        ScanClassifier(
            largeFileThresholdBytes: threshold,
            homeDirectory: homeDirectory,
            temporaryDirectory: temporaryDirectory
        )
    }

    public func classify(url: URL, sizeBytes: Int64, isDirectory: Bool) -> ScanClassification {
        let baseClassification: ScanClassification

        if isInside(url, roots: [
            homeDirectory.appending(path: "Library/Caches", directoryHint: .isDirectory),
            URL(filePath: "/Library/Caches", directoryHint: .isDirectory)
        ]) {
            baseClassification = ScanClassification(
                category: .cache,
                risk: .usuallySafe,
                reasons: ["Cache directory item"]
            )
        } else if isInside(url, roots: [
            homeDirectory.appending(path: "Library/Logs", directoryHint: .isDirectory),
            URL(filePath: "/Library/Logs", directoryHint: .isDirectory)
        ]) {
            baseClassification = ScanClassification(
                category: .logs,
                risk: .usuallySafe,
                reasons: ["Logs directory item"]
            )
        } else if isInside(url, roots: [
            homeDirectory.appending(path: "Downloads", directoryHint: .isDirectory)
        ]) {
            baseClassification = ScanClassification(
                category: .downloads,
                risk: .reviewRecommended,
                reasons: ["Downloads folder item"]
            )
        } else if isInside(url, roots: [
            homeDirectory.appending(path: ".Trash", directoryHint: .isDirectory)
        ]) || normalizedPaths(url).contains(where: isVolumeTrashPath) {
            baseClassification = ScanClassification(
                category: .trash,
                risk: .usuallySafe,
                reasons: ["Already in Trash"]
            )
        } else if isInside(url, roots: [
            temporaryDirectory,
            URL(filePath: "/tmp", directoryHint: .isDirectory),
            URL(filePath: "/private/tmp", directoryHint: .isDirectory),
            URL(filePath: "/var/tmp", directoryHint: .isDirectory),
            URL(filePath: "/private/var/tmp", directoryHint: .isDirectory)
        ]) {
            baseClassification = ScanClassification(
                category: .temporary,
                risk: .usuallySafe,
                reasons: ["Temporary file location"]
            )
        } else if isInside(url, roots: [
            homeDirectory.appending(path: "Library/Developer", directoryHint: .isDirectory)
        ]) {
            baseClassification = ScanClassification(
                category: .developer,
                risk: .reviewRecommended,
                reasons: ["Developer cache or Xcode-derived data"]
            )
        } else if sizeBytes >= largeFileThresholdBytes {
            baseClassification = ScanClassification(
                category: .largeFile,
                risk: .reviewRecommended,
                reasons: ["Large file above configured threshold"]
            )
        } else {
            baseClassification = ScanClassification(
                category: .other,
                risk: isDirectory ? .beCareful : .reviewRecommended,
                reasons: ["No cleanup-specific pattern matched"]
            )
        }

        let safety = safetyRuleEngine.evaluate(
            url: url,
            category: baseClassification.category,
            risk: baseClassification.risk,
            reasons: baseClassification.reasons,
            isDirectory: isDirectory
        )

        return ScanClassification(
            category: baseClassification.category,
            risk: baseClassification.risk,
            reasons: baseClassification.reasons,
            protection: safety.protection,
            ruleMatches: safety.ruleMatches,
            userVisibleRules: safety.userVisibleRules
        )
    }

    private func isInside(_ url: URL, roots: [URL]) -> Bool {
        let paths = normalizedPaths(url)
        return roots.contains { root in
            normalizedPaths(root).contains { rootPath in
                let descendantPrefix = rootPath == "/" ? "/" : rootPath + "/"
                return paths.contains { path in
                    path == rootPath || path.hasPrefix(descendantPrefix)
                }
            }
        }
    }

    private func normalizedPaths(_ url: URL) -> Set<String> {
        [
            normalizedPath(url.path),
            normalizedPath(url.resolvingSymlinksInPath().path)
        ]
    }

    /// Comparison-only normalization: APFS is case-insensitive by default, so both
    /// sides are lowercased (matching SafetyRuleEngine). Never use the result for
    /// user-facing paths or copy.
    private func normalizedPath(_ path: String) -> String {
        var components: [Substring] = []
        for component in path.lowercased().split(separator: "/") {
            switch component {
            case ".":
                continue
            case "..":
                if !components.isEmpty { components.removeLast() }
            default:
                components.append(component)
            }
        }
        return "/" + components.joined(separator: "/")
    }

    private func isVolumeTrashPath(_ path: String) -> Bool {
        let components = path.lowercased().split(separator: "/")
        if components.first == ".trashes" {
            return true
        }
        return components.count >= 3
            && components[0] == "volumes"
            && components[2] == ".trashes"
    }
}
