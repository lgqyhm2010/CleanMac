import Foundation

public enum ResolvedLanguage: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case english
    case chinese
    case chineseTraditional
    case japanese
    case spanish
    case french
    case arabic
    case hindi
    case portuguese
    case russian
    case bengali

    var lprojName: String {
        switch self {
        case .english: return "en"
        case .chinese: return "zh-Hans"
        case .chineseTraditional: return "zh-Hant"
        case .japanese: return "ja"
        case .spanish: return "es"
        case .french: return "fr"
        case .arabic: return "ar"
        case .hindi: return "hi"
        case .portuguese: return "pt-BR"
        case .russian: return "ru"
        case .bengali: return "bn"
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
    case chineseTraditional
    case japanese
    case spanish
    case french
    case arabic
    case hindi
    case portuguese
    case russian
    case bengali

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
        case .chineseTraditional:
            return .chineseTraditional
        case .japanese:
            return .japanese
        case .spanish:
            return .spanish
        case .french:
            return .french
        case .arabic:
            return .arabic
        case .hindi:
            return .hindi
        case .portuguese:
            return .portuguese
        case .russian:
            return .russian
        case .bengali:
            return .bengali
        case .system:
            for preferredLanguage in preferredLanguages {
                if let language = ResolvedLanguage(preferredLanguage: preferredLanguage) {
                    return language
                }
            }
            return .english
        }
    }
}

private extension ResolvedLanguage {
    init?(preferredLanguage: String) {
        let normalized = preferredLanguage
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()

        if normalized.hasPrefix("zh-hant")
            || normalized.hasPrefix("zh-tw")
            || normalized.hasPrefix("zh-hk")
            || normalized.hasPrefix("zh-mo") {
            self = .chineseTraditional
        } else if normalized.hasPrefix("zh") {
            self = .chinese
        } else if normalized.hasPrefix("ja") {
            self = .japanese
        } else if normalized.hasPrefix("es") {
            self = .spanish
        } else if normalized.hasPrefix("fr") {
            self = .french
        } else if normalized.hasPrefix("ar") {
            self = .arabic
        } else if normalized.hasPrefix("hi") {
            self = .hindi
        } else if normalized.hasPrefix("pt") {
            self = .portuguese
        } else if normalized.hasPrefix("ru") {
            self = .russian
        } else if normalized.hasPrefix("bn") {
            self = .bengali
        } else if normalized.hasPrefix("en") {
            self = .english
        } else {
            return nil
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
