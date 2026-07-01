import Foundation

public enum MenuBarMonitorSummary {
    public static func title(
        status: CleaningStatus,
        candidateCount: Int,
        isScanning: Bool,
        language: ResolvedLanguage = .english
    ) -> String {
        if isScanning || status == .scanning {
            return L10n.status(.scanning, language: language)
        }

        switch status {
        case .scanning:
            return L10n.status(.scanning, language: language)
        case .movingToTrash:
            return L10n.text(.moving, language: language)
        case .askingAI:
            return L10n.text(.aiReview, language: language)
        case .candidatesFound(let statusCount):
            let count = max(statusCount, candidateCount)
            return count > 0 ? L10n.candidateCount(count, language: language) : "CleanMac"
        case .movedToTrash, .aiReviewFinished:
            return candidateCount > 0 ? L10n.candidateCount(candidateCount, language: language) : "CleanMac"
        case .ready, .scanFailed, .cleanupFailed, .aiReviewFailed:
            return "CleanMac"
        }
    }
}
