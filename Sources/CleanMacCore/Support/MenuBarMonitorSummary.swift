import Foundation

public enum MenuBarMonitorSummary {
    public static func title(
        status: CleaningStatus,
        candidateCount: Int,
        isScanning: Bool
    ) -> String {
        if isScanning || status == .scanning {
            return "Scanning..."
        }

        switch status {
        case .scanning:
            return "Scanning..."
        case .movingToTrash:
            return "Moving..."
        case .askingAI:
            return "AI review"
        case .candidatesFound(let statusCount):
            let count = max(statusCount, candidateCount)
            return count > 0 ? "\(count) items" : "CleanMac"
        case .movedToTrash, .aiReviewFinished:
            return candidateCount > 0 ? "\(candidateCount) items" : "CleanMac"
        case .ready, .scanFailed, .cleanupFailed, .aiReviewFailed:
            return "CleanMac"
        }
    }
}
