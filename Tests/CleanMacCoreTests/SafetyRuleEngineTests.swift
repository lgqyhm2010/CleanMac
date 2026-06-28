import XCTest
@testable import CleanMacCore

final class SafetyRuleEngineTests: XCTestCase {
    func testProtectsSystemAndApplicationDataPaths() {
        let engine = SafetyRuleEngine()

        let system = engine.evaluate(
            url: URL(filePath: "/System/Library/Extensions/Audio.kext"),
            category: .other,
            risk: .reviewRecommended,
            reasons: []
        )
        XCTAssertEqual(system.protection, .blocked)
        XCTAssertTrue(system.ruleMatches.contains { $0.ruleID == "system-root" })
        XCTAssertTrue(system.userVisibleRules.contains { $0.localizedCaseInsensitiveContains("system") })

        let appData = engine.evaluate(
            url: URL(filePath: "/Users/me/Library/Application Support/ImportantApp/database.sqlite"),
            category: .other,
            risk: .reviewRecommended,
            reasons: []
        )
        XCTAssertEqual(appData.protection, .blocked)
        XCTAssertTrue(appData.ruleMatches.contains { $0.ruleID == "app-data" })
    }

    func testMarksSourceCodeForManualReviewInsteadOfTreatingItAsSafeDeveloperCache() {
        let engine = SafetyRuleEngine()

        let source = engine.evaluate(
            url: URL(filePath: "/Users/me/Projects/App/Sources/main.swift"),
            category: .developer,
            risk: .reviewRecommended,
            reasons: []
        )

        XCTAssertEqual(source.protection, .requiresReview)
        XCTAssertTrue(source.ruleMatches.contains { $0.ruleID == "source-code" })
        XCTAssertTrue(source.userVisibleRules.contains { $0.localizedCaseInsensitiveContains("source") })
    }

    func testCloudStoragePathsRequireReviewWithVisibleRule() {
        let engine = SafetyRuleEngine()

        let iCloud = engine.evaluate(
            url: URL(filePath: "/Users/me/Library/Mobile Documents/com~apple~CloudDocs/Archive.zip"),
            category: .largeFile,
            risk: .reviewRecommended,
            reasons: []
        )
        XCTAssertEqual(iCloud.protection, .requiresReview)
        XCTAssertTrue(iCloud.ruleMatches.contains { $0.ruleID == "cloud-storage" })
        XCTAssertTrue(iCloud.userVisibleRules.contains { $0.localizedCaseInsensitiveContains("cloud") })

        let oneDrive = engine.evaluate(
            url: URL(filePath: "/Users/me/Library/CloudStorage/OneDrive-Personal/report.pdf"),
            category: .downloads,
            risk: .reviewRecommended,
            reasons: []
        )
        XCTAssertEqual(oneDrive.protection, .requiresReview)
        XCTAssertTrue(oneDrive.ruleMatches.contains { $0.ruleID == "cloud-storage" })

        let dropbox = engine.evaluate(
            url: URL(filePath: "/Users/me/Dropbox/shared.mov"),
            category: .largeFile,
            risk: .reviewRecommended,
            reasons: []
        )
        XCTAssertEqual(dropbox.protection, .requiresReview)
        XCTAssertTrue(dropbox.ruleMatches.contains { $0.ruleID == "cloud-storage" })
    }

    func testAllowsCleanupRulesForCacheLogsTemporaryAndTrashCandidates() {
        let engine = SafetyRuleEngine()

        let cache = engine.evaluate(
            url: URL(filePath: "/Users/me/Library/Caches/com.example/blob.cache"),
            category: .cache,
            risk: .usuallySafe,
            reasons: ["Cache directory item"]
        )
        XCTAssertEqual(cache.protection, .allowed)
        XCTAssertTrue(cache.ruleMatches.contains { $0.ruleID == "cache" })
        XCTAssertTrue(cache.userVisibleRules.contains { $0.localizedCaseInsensitiveContains("cache") })

        let log = engine.evaluate(
            url: URL(filePath: "/Users/me/Library/Logs/example.log"),
            category: .logs,
            risk: .usuallySafe,
            reasons: ["Log file or Logs directory item"]
        )
        XCTAssertEqual(log.protection, .allowed)
        XCTAssertTrue(log.ruleMatches.contains { $0.ruleID == "logs" })

        let temporary = engine.evaluate(
            url: URL(filePath: "/private/tmp/CleanMac/file.tmp"),
            category: .temporary,
            risk: .usuallySafe,
            reasons: ["Temporary file location or extension"]
        )
        XCTAssertEqual(temporary.protection, .allowed)
        XCTAssertTrue(temporary.ruleMatches.contains { $0.ruleID == "temporary" })

        let trash = engine.evaluate(
            url: URL(filePath: "/Users/me/.Trash/old-item"),
            category: .trash,
            risk: .usuallySafe,
            reasons: ["Already in Trash"]
        )
        XCTAssertEqual(trash.protection, .allowed)
        XCTAssertTrue(trash.ruleMatches.contains { $0.ruleID == "trash" })
    }

    func testReviewRulesForDownloadsLargeFilesAndUnknownDirectoriesStayVisible() {
        let engine = SafetyRuleEngine()

        let download = engine.evaluate(
            url: URL(filePath: "/Users/me/Downloads/installer.dmg"),
            category: .downloads,
            risk: .reviewRecommended,
            reasons: ["Downloads folder item"]
        )
        XCTAssertEqual(download.protection, .requiresReview)
        XCTAssertTrue(download.ruleMatches.contains { $0.ruleID == "downloads" })

        let large = engine.evaluate(
            url: URL(filePath: "/Users/me/Movies/export.mov"),
            category: .largeFile,
            risk: .reviewRecommended,
            reasons: ["Large file above configured threshold"]
        )
        XCTAssertEqual(large.protection, .requiresReview)
        XCTAssertTrue(large.ruleMatches.contains { $0.ruleID == "large-file" })

        let unknownDirectory = engine.evaluate(
            url: URL(filePath: "/Users/me/Documents/Archive"),
            category: .other,
            risk: .beCareful,
            reasons: ["No cleanup-specific pattern matched"],
            isDirectory: true
        )
        XCTAssertEqual(unknownDirectory.protection, .blocked)
        XCTAssertTrue(unknownDirectory.ruleMatches.contains { $0.ruleID == "unknown-directory" })
    }
}
