import CleanMacCore
import Foundation

enum Formatters {
    static func bytes(_ value: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        return formatter.string(fromByteCount: value)
    }

    static func date(_ value: Date?) -> String {
        guard let value else { return "Unknown" }
        return value.formatted(date: .abbreviated, time: .shortened)
    }

    static func date(_ value: Date?, language: ResolvedLanguage) -> String {
        guard let value else { return L10n.text(.unknown, language: language) }
        return value.formatted(date: .abbreviated, time: .shortened)
    }
}
