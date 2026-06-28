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

    var symbolName: String {
        switch self {
        case .scan: "magnifyingglass"
        case .results: "list.bullet.rectangle"
        case .aiReview: "sparkles"
        }
    }
}
