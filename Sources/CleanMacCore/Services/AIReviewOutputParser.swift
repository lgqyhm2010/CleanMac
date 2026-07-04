import Foundation

public struct AIReviewItem: Equatable, Sendable, Identifiable {
    public var id: String { path + (reason ?? "") }
    public let path: String
    public let reason: String?

    public init(path: String, reason: String?) {
        self.path = path
        self.reason = reason
    }
}

public struct AIReviewSummary: Equatable, Sendable {
    public let summary: String?
    public let safeToDelete: [AIReviewItem]
    public let risky: [AIReviewItem]
    public let needsUserReview: [AIReviewItem]

    public init(summary: String?, safeToDelete: [AIReviewItem], risky: [AIReviewItem], needsUserReview: [AIReviewItem]) {
        self.summary = summary
        self.safeToDelete = safeToDelete
        self.risky = risky
        self.needsUserReview = needsUserReview
    }
}

/// Tolerant parser for the JSON the review prompt requests. Models wrap JSON in
/// markdown fences or prose despite instructions, and element shapes drift
/// (bare path strings, alternate key names) — every stage here degrades to nil
/// rather than throwing, and nil means "show the raw text instead".
public enum AIReviewOutputParser {
    public static func parse(_ raw: String) -> AIReviewSummary? {
        guard let jsonObject = extractJSONObject(from: raw) else { return nil }

        let summary = (jsonObject["summary"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeToDelete = items(from: jsonObject["safe_to_delete"])
        let risky = items(from: jsonObject["risky"])
        let needsUserReview = items(from: jsonObject["needs_user_review"])

        let hasContent = !(summary ?? "").isEmpty || !safeToDelete.isEmpty || !risky.isEmpty || !needsUserReview.isEmpty
        guard hasContent else { return nil }

        return AIReviewSummary(
            summary: (summary ?? "").isEmpty ? nil : summary,
            safeToDelete: safeToDelete,
            risky: risky,
            needsUserReview: needsUserReview
        )
    }

    /// Finds the outermost JSON object even when it is wrapped in markdown
    /// fences or surrounded by prose.
    private static func extractJSONObject(from raw: String) -> [String: Any]? {
        let withoutFences = raw.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
        guard
            let start = withoutFences.firstIndex(of: "{"),
            let end = withoutFences.lastIndex(of: "}"),
            start < end,
            let data = String(withoutFences[start...end]).data(using: .utf8)
        else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    private static let pathKeys = ["path", "file", "url"]
    private static let reasonKeys = ["reason", "note", "why"]

    private static func items(from value: Any?) -> [AIReviewItem] {
        guard let array = value as? [Any] else { return [] }
        return array.compactMap { element in
            if let path = element as? String {
                let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : AIReviewItem(path: trimmed, reason: nil)
            }
            if let object = element as? [String: Any] {
                guard let path = firstString(in: object, keys: pathKeys) else { return nil }
                return AIReviewItem(path: path, reason: firstString(in: object, keys: reasonKeys))
            }
            return nil
        }
    }

    private static func firstString(in object: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = (object[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }
        return nil
    }
}
