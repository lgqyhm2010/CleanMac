import Foundation
import Testing
@testable import CleanMacCore

@Suite("Localization")
struct LocalizationTests {
    @Test("system language resolves Chinese preferred locales")
    func systemLanguageResolvesChinesePreferredLocales() {
        #expect(AppLanguage.system.resolved(preferredLanguages: ["zh-Hans-US", "en-US"]) == .chinese)
        #expect(AppLanguage.system.resolved(preferredLanguages: ["zh-Hant-TW", "en-US"]) == .chineseTraditional)
    }

    @Test("system language resolves all supported preferred locales")
    func systemLanguageResolvesAllSupportedPreferredLocales() {
        #expect(AppLanguage.system.resolved(preferredLanguages: ["ja-JP", "en-US"]) == .japanese)
        #expect(AppLanguage.system.resolved(preferredLanguages: ["es-MX", "en-US"]) == .spanish)
        #expect(AppLanguage.system.resolved(preferredLanguages: ["fr-FR", "en-US"]) == .french)
        #expect(AppLanguage.system.resolved(preferredLanguages: ["ar-SA", "en-US"]) == .arabic)
        #expect(AppLanguage.system.resolved(preferredLanguages: ["hi-IN", "en-US"]) == .hindi)
        #expect(AppLanguage.system.resolved(preferredLanguages: ["pt-BR", "en-US"]) == .portuguese)
        #expect(AppLanguage.system.resolved(preferredLanguages: ["ru-RU", "en-US"]) == .russian)
        #expect(AppLanguage.system.resolved(preferredLanguages: ["bn-BD", "en-US"]) == .bengali)
        #expect(AppLanguage.system.resolved(preferredLanguages: ["de-DE", "fr-FR"]) == .french)
    }

    @Test("system language falls back to English for non-Chinese locales")
    func systemLanguageFallsBackToEnglish() {
        #expect(AppLanguage.system.resolved(preferredLanguages: ["en-US", "zh-Hans"]) == .english)
        #expect(AppLanguage.system.resolved(preferredLanguages: ["de-DE", "it-IT"]) == .english)
        #expect(AppLanguage.system.resolved(preferredLanguages: []) == .english)
    }

    @Test("stored language defaults to system")
    func storedLanguageDefaultsToSystem() {
        #expect(AppLanguage(storedRawValue: nil) == .system)
        #expect(AppLanguage(storedRawValue: "bogus") == .system)
        #expect(AppLanguage(storedRawValue: "chinese") == .chinese)
        #expect(AppLanguage(storedRawValue: "japanese") == .japanese)
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
        let staticKeys = Set(L10n.Key.allCases.map { String(describing: $0) })

        for strings in try loadAllLanguageStrings() {
            #expect(staticKeys.isSubset(of: Set(strings.keys)))
        }

        #expect(try loadStrings(for: .english)["scan"] == "Scan")
        #expect(try loadStrings(for: .chinese)["scan"] == "扫描")
        #expect(try loadStrings(for: .japanese)["scan"] == "スキャン")
    }

    @Test("Localizable.strings resources cover dynamic L10n keys")
    func localizableStringsResourcesCoverDynamicL10nKeys() throws {
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

        for strings in try loadAllLanguageStrings() {
            #expect(dynamicKeys.isSubset(of: Set(strings.keys)))
        }

        #expect(L10n.status(.movedToTrash(3), language: .chinese) == "已将 3 个项目移到废纸篓")
        #expect(L10n.scanReason("Application bundle for com.example.demo", language: .english) == "Application bundle for com.example.demo")
        #expect(L10n.scanReason("Application bundle for com.example.demo", language: .chinese) == "com.example.demo 应用程序包")
    }

    @Test("Every resolved language has a strings resource")
    func everyResolvedLanguageHasAStringsResource() throws {
        let resourcesURL = packageRoot().appending(path: "Sources/CleanMacCore/Resources")

        for language in ResolvedLanguage.allCases {
            let stringsURL = resourcesURL.appending(path: "\(language.lprojName).lproj/Localizable.strings")
            #expect(FileManager.default.fileExists(atPath: stringsURL.path))
        }
    }

    @Test("HTML prototype exposes every supported language")
    func htmlPrototypeExposesEverySupportedLanguage() throws {
        let htmlURL = packageRoot().appending(path: "cleanmac_with_ai.html")
        let html = try String(contentsOf: htmlURL, encoding: .utf8)
        let expectedCodes = ["en", "zh", "zh-Hant", "ja", "es", "fr", "ar", "hi", "pt-BR", "ru", "bn"]

        let languageCodeCount = html.components(separatedBy: "{code:'").count - 1
        #expect(languageCodeCount == expectedCodes.count)

        for code in expectedCodes {
            #expect(html.contains("{code:'\(code)'"))

            let i18nKey = code.contains("-") ? "'\(code)':{" : "\(code):{"
            #expect(html.contains(i18nKey))
        }
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

    private func loadAllLanguageStrings() throws -> [[String: String]] {
        try ResolvedLanguage.allCases.map(loadStrings(for:))
    }

    private func loadStrings(for language: ResolvedLanguage) throws -> [String: String] {
        let resourcesURL = packageRoot().appending(path: "Sources/CleanMacCore/Resources")
        return try loadStrings(from: resourcesURL.appending(path: "\(language.lprojName).lproj/Localizable.strings"))
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
