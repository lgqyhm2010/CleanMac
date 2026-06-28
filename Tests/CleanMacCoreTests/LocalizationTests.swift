import Foundation
import Testing
@testable import CleanMacCore

@Suite("Localization")
struct LocalizationTests {
    @Test("system language resolves Chinese preferred locales")
    func systemLanguageResolvesChinesePreferredLocales() {
        #expect(AppLanguage.system.resolved(preferredLanguages: ["zh-Hans-US", "en-US"]) == .chinese)
        #expect(AppLanguage.system.resolved(preferredLanguages: ["zh-Hant-TW", "en-US"]) == .chinese)
    }

    @Test("system language falls back to English for non-Chinese locales")
    func systemLanguageFallsBackToEnglish() {
        #expect(AppLanguage.system.resolved(preferredLanguages: ["en-US", "zh-Hans"]) == .english)
        #expect(AppLanguage.system.resolved(preferredLanguages: []) == .english)
    }

    @Test("stored language defaults to system")
    func storedLanguageDefaultsToSystem() {
        #expect(AppLanguage(storedRawValue: nil) == .system)
        #expect(AppLanguage(storedRawValue: "bogus") == .system)
        #expect(AppLanguage(storedRawValue: "chinese") == .chinese)
    }

    @Test("Chinese translations cover core cleanup labels")
    func chineseTranslationsCoverCoreCleanupLabels() {
        #expect(CandidateCategory.cache.displayName(language: .chinese) == "缓存")
        #expect(CandidateCategory.largeFile.displayName(language: .chinese) == "大文件")
        #expect(DeletionRisk.beCareful.displayName(language: .chinese) == "谨慎处理")
        #expect(L10n.text(.scan, language: .chinese) == "扫描")
        #expect(L10n.scanReason("Cache directory item", language: .chinese) == "缓存目录项目")
    }

    @Test("Localizable.strings resources cover every static L10n key")
    func localizableStringsResourcesCoverEveryStaticL10nKey() throws {
        let resourcesURL = packageRoot().appending(path: "Sources/CleanMacCore/Resources")
        let english = try loadStrings(from: resourcesURL.appending(path: "en.lproj/Localizable.strings"))
        let chinese = try loadStrings(from: resourcesURL.appending(path: "zh-Hans.lproj/Localizable.strings"))
        let staticKeys = Set(L10n.Key.allCases.map { String(describing: $0) })

        #expect(staticKeys.isSubset(of: Set(english.keys)))
        #expect(staticKeys.isSubset(of: Set(chinese.keys)))
        #expect(english["scan"] == "Scan")
        #expect(chinese["scan"] == "扫描")
    }

    @Test("Localizable.strings resources cover dynamic L10n keys")
    func localizableStringsResourcesCoverDynamicL10nKeys() throws {
        let resourcesURL = packageRoot().appending(path: "Sources/CleanMacCore/Resources")
        let english = try loadStrings(from: resourcesURL.appending(path: "en.lproj/Localizable.strings"))
        let chinese = try loadStrings(from: resourcesURL.appending(path: "zh-Hans.lproj/Localizable.strings"))
        let dynamicKeys = Set([
            "category.cache",
            "risk.beCareful",
            "protection.blocked",
            "permissionStatus.granted",
            "permission.fullDiskAccess.title",
            "permission.fullDiskAccess.instruction.1",
            "protectedItemCount",
            "moveToTrashSummary.protected",
            "scanReason.applicationBundle",
            "folderCount",
            "duplicateGroupDetail",
            "appUninstallPlanDetail",
            "status.candidatesFound",
            "status.movedToTrash",
            "error.itemsCouldNotBeMoved",
            "defaultAIQuestion"
        ])

        #expect(dynamicKeys.isSubset(of: Set(english.keys)))
        #expect(dynamicKeys.isSubset(of: Set(chinese.keys)))
        #expect(L10n.status(.movedToTrash(3), language: .chinese) == "已将 3 个项目移到废纸篓")
        #expect(L10n.scanReason("Application bundle for com.example.demo", language: .english) == "Application bundle for com.example.demo")
        #expect(L10n.scanReason("Application bundle for com.example.demo", language: .chinese) == "应用程序包")
    }

    @Test("Localized copy is not stored in hardcoded language tables")
    func localizedCopyIsNotStoredInHardcodedLanguageTables() throws {
        let l10nSourceURL = packageRoot().appending(path: "Sources/CleanMacCore/Localization/L10n.swift")
        let source = try String(contentsOf: l10nSourceURL, encoding: .utf8)

        #expect(source.contains("Bundle.module"))
        #expect(!source.contains("private static func englishText"))
        #expect(!source.contains("private static func chineseText"))
    }

    private func packageRoot() -> URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func loadStrings(from url: URL) throws -> [String: String] {
        let content = try String(contentsOf: url, encoding: .utf8)
        var strings: [String: String] = [:]

        for line in content.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedLine.hasPrefix("\""), trimmedLine.hasSuffix(";") else { continue }

            let parts = trimmedLine.split(separator: "\"", omittingEmptySubsequences: false)
            guard parts.count >= 4 else { continue }
            strings[String(parts[1])] = String(parts[3])
        }

        return strings
    }
}
