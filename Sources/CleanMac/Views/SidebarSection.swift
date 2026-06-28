import CleanMacCore
import Foundation

enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case scan
    case results
    case aiReview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scan: "Scan"
        case .results: "Results"
        case .aiReview: "AI Review"
        }
    }

    func title(language: ResolvedLanguage) -> String {
        switch self {
        case .scan: L10n.text(.scan, language: language)
        case .results: L10n.text(.results, language: language)
        case .aiReview: L10n.text(.aiReview, language: language)
        }
    }

    var symbolName: String {
        switch self {
        case .scan: "magnifyingglass"
        case .results: "list.bullet.rectangle"
        case .aiReview: "sparkles"
        }
    }
}
