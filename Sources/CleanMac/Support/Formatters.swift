import CleanMacCore
import Foundation

enum Formatters {
    // Formatters are expensive to create; cache one instance. All callers are
    // SwiftUI views, so MainActor isolation covers the formatter's mutability.
    @MainActor
    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        return formatter
    }()

    @MainActor
    static func bytes(_ value: Int64) -> String {
        byteCountFormatter.string(fromByteCount: value)
    }

    static func date(_ value: Date?, language: ResolvedLanguage) -> String {
        guard let value else { return L10n.text(.unknown, language: language) }
        return value.formatted(date: .abbreviated, time: .shortened)
    }
}
