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
}
