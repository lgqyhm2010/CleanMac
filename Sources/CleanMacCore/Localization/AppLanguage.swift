import Foundation

public enum ResolvedLanguage: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case english
    case chinese

    var lprojName: String {
        switch self {
        case .english: return "en"
        case .chinese: return "zh-Hans"
        }
    }

    var locale: Locale {
        Locale(identifier: lprojName)
    }
}

public enum AppLanguage: String, CaseIterable, Codable, Equatable, Hashable, Identifiable, Sendable {
    case system
    case english
    case chinese

    public static let storageKey = "appLanguage"

    public var id: String { rawValue }

    public init(storedRawValue: String?) {
        self = storedRawValue.flatMap(Self.init(rawValue:)) ?? .system
    }

    public func resolved(preferredLanguages: [String] = Locale.preferredLanguages) -> ResolvedLanguage {
        switch self {
        case .english:
            return .english
        case .chinese:
            return .chinese
        case .system:
            guard let firstLanguage = preferredLanguages.first?.lowercased() else {
                return .english
            }
            return firstLanguage.hasPrefix("zh") ? .chinese : .english
        }
    }
}

public enum CleaningStatus: Equatable, Sendable {
    case ready
    case scanning
    case candidatesFound(Int)
    case scanFailed
    case movingToTrash
    case movedToTrash(Int)
    case cleanupFailed
    case askingAI
    case aiReviewFinished
    case aiReviewFailed
}

public enum CleaningErrorMessage: Equatable, Sendable {
    case addFolderToScan
    case itemsCouldNotBeMoved(Int)
    case itemsWereProtected(Int)
    case selectItemForAIReview
    case setAIExecutable
    case system(String)
}
