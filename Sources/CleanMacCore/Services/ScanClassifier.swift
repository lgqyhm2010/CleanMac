import Foundation

public struct ScanClassifier: Sendable {
    private let largeFileThresholdBytes: Int64

    public init(largeFileThresholdBytes: Int64 = 500 * 1_024 * 1_024) {
        self.largeFileThresholdBytes = largeFileThresholdBytes
    }

    public func classify(url: URL, sizeBytes: Int64, isDirectory: Bool) -> ScanClassification {
        let lowerPath = url.path.lowercased()
        let lowerComponents = url.pathComponents.map { $0.lowercased() }

        if lowerComponents.contains("caches") || lowerPath.contains("/library/caches/") {
            return ScanClassification(
                category: .cache,
                risk: .usuallySafe,
                reasons: ["Cache directory item"]
            )
        }

        if lowerComponents.contains("logs") || url.pathExtension.lowercased() == "log" {
            return ScanClassification(
                category: .logs,
                risk: .usuallySafe,
                reasons: ["Log file or Logs directory item"]
            )
        }

        if lowerComponents.contains("downloads") {
            return ScanClassification(
                category: .downloads,
                risk: .reviewRecommended,
                reasons: ["Downloads folder item"]
            )
        }

        if lowerComponents.contains(".trash") || lowerComponents.contains("trash") {
            return ScanClassification(
                category: .trash,
                risk: .usuallySafe,
                reasons: ["Already in Trash"]
            )
        }

        if lowerComponents.contains("tmp")
            || lowerComponents.contains("temporaryitems")
            || url.pathExtension.lowercased() == "tmp" {
            return ScanClassification(
                category: .temporary,
                risk: .usuallySafe,
                reasons: ["Temporary file location or extension"]
            )
        }

        if lowerComponents.contains("deriveddata")
            || lowerPath.contains("/developer/xcode/")
            || lowerPath.contains("/library/developer/") {
            return ScanClassification(
                category: .developer,
                risk: .reviewRecommended,
                reasons: ["Developer cache or Xcode-derived data"]
            )
        }

        if sizeBytes >= largeFileThresholdBytes {
            return ScanClassification(
                category: .largeFile,
                risk: .reviewRecommended,
                reasons: ["Large file above configured threshold"]
            )
        }

        return ScanClassification(
            category: .other,
            risk: isDirectory ? .beCareful : .reviewRecommended,
            reasons: ["No cleanup-specific pattern matched"]
        )
    }
}
