import Foundation

public struct ScanClassifier: Sendable {
    private let largeFileThresholdBytes: Int64
    private let safetyRuleEngine: SafetyRuleEngine

    public init(largeFileThresholdBytes: Int64 = 500 * 1_024 * 1_024) {
        self.largeFileThresholdBytes = largeFileThresholdBytes
        self.safetyRuleEngine = SafetyRuleEngine()
    }

    public func classify(url: URL, sizeBytes: Int64, isDirectory: Bool) -> ScanClassification {
        let lowerPath = url.path.lowercased()
        let lowerComponents = url.pathComponents.map { $0.lowercased() }
        let baseClassification: ScanClassification

        if lowerComponents.contains("caches") || lowerPath.contains("/library/caches/") {
            baseClassification = ScanClassification(
                category: .cache,
                risk: .usuallySafe,
                reasons: ["Cache directory item"]
            )
        } else if lowerComponents.contains("logs") || url.pathExtension.lowercased() == "log" {
            baseClassification = ScanClassification(
                category: .logs,
                risk: .usuallySafe,
                reasons: ["Log file or Logs directory item"]
            )
        } else if lowerComponents.contains("downloads") {
            baseClassification = ScanClassification(
                category: .downloads,
                risk: .reviewRecommended,
                reasons: ["Downloads folder item"]
            )
        } else if lowerComponents.contains(".trash") || lowerComponents.contains("trash") {
            baseClassification = ScanClassification(
                category: .trash,
                risk: .usuallySafe,
                reasons: ["Already in Trash"]
            )
        } else if lowerComponents.contains("tmp")
            || lowerComponents.contains("temporaryitems")
            || url.pathExtension.lowercased() == "tmp" {
            baseClassification = ScanClassification(
                category: .temporary,
                risk: .usuallySafe,
                reasons: ["Temporary file location or extension"]
            )
        } else if lowerComponents.contains("deriveddata")
            || lowerPath.contains("/developer/xcode/")
            || lowerPath.contains("/library/developer/") {
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
}
