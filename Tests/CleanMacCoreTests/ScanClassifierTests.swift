import XCTest
@testable import CleanMacCore

final class ScanClassifierTests: XCTestCase {
    func testClassifiesCommonCleanupLocationsWithRiskHints() {
        let classifier = ScanClassifier(
            largeFileThresholdBytes: 100,
            homeDirectory: URL(filePath: "/Users/me", directoryHint: .isDirectory)
        )

        let cache = classifier.classify(
            url: URL(filePath: "/Users/me/Library/Caches/com.example/blob.cache"),
            sizeBytes: 42,
            isDirectory: false
        )
        XCTAssertEqual(cache.category, .cache)
        XCTAssertEqual(cache.risk, .usuallySafe)
        XCTAssertTrue(cache.reasons.contains { $0.localizedCaseInsensitiveContains("cache") })

        let log = classifier.classify(
            url: URL(filePath: "/Users/me/Library/Logs/example.log"),
            sizeBytes: 42,
            isDirectory: false
        )
        XCTAssertEqual(log.category, .logs)
        XCTAssertEqual(log.risk, .usuallySafe)

        let download = classifier.classify(
            url: URL(filePath: "/Users/me/Downloads/installer.dmg"),
            sizeBytes: 42,
            isDirectory: false
        )
        XCTAssertEqual(download.category, .downloads)
        XCTAssertEqual(download.risk, .reviewRecommended)

        let large = classifier.classify(
            url: URL(filePath: "/Users/me/Movies/export.mov"),
            sizeBytes: 101,
            isDirectory: false
        )
        XCTAssertEqual(large.category, .largeFile)
        XCTAssertEqual(large.risk, .reviewRecommended)
    }

    func testDoesNotTreatUserFoldersNamedTrashOrTmpAsSafeToDelete() {
        let classifier = ScanClassifier(
            largeFileThresholdBytes: 100,
            homeDirectory: URL(filePath: "/Users/me", directoryHint: .isDirectory)
        )

        let userTrash = classifier.classify(
            url: URL(filePath: "/Users/me/Documents/trash/keepsake.txt"),
            sizeBytes: 42,
            isDirectory: false
        )
        XCTAssertNotEqual(userTrash.category, .trash)
        XCTAssertNotEqual(userTrash.risk, .usuallySafe)

        let userTmp = classifier.classify(
            url: URL(filePath: "/Users/me/Projects/app/tmp/build.o"),
            sizeBytes: 42,
            isDirectory: false
        )
        XCTAssertNotEqual(userTmp.category, .temporary)
        XCTAssertNotEqual(userTmp.risk, .usuallySafe)
    }

    func testStillClassifiesRealTrashAndTempLocations() {
        let classifier = ScanClassifier(
            largeFileThresholdBytes: 100,
            homeDirectory: URL(filePath: "/Users/me", directoryHint: .isDirectory)
        )

        let realTrash = classifier.classify(
            url: URL(filePath: "/Users/me/.Trash/old-installer.dmg"),
            sizeBytes: 42,
            isDirectory: false
        )
        XCTAssertEqual(realTrash.category, .trash)
        XCTAssertEqual(realTrash.risk, .usuallySafe)

        let realTemp = classifier.classify(
            url: URL(filePath: "/private/tmp/scratch.dat"),
            sizeBytes: 42,
            isDirectory: false
        )
        XCTAssertEqual(realTemp.category, .temporary)
        XCTAssertEqual(realTemp.risk, .usuallySafe)
    }

    func testCleanupNamesAndExtensionsOutsideStandardRootsStayReviewOnly() {
        let classifier = ScanClassifier(
            largeFileThresholdBytes: 100,
            homeDirectory: URL(filePath: "/Users/me", directoryHint: .isDirectory)
        )
        let arbitraryPaths = [
            "/Users/me/Documents/Caches/keepsake.bin",
            "/Users/me/Documents/Logs/journal.txt",
            "/Users/me/Documents/Downloads/archive.zip",
            "/Users/me/Documents/journal.log",
            "/Users/me/Documents/contract.tmp"
        ]

        for path in arbitraryPaths {
            let classification = classifier.classify(
                url: URL(filePath: path),
                sizeBytes: 42,
                isDirectory: false
            )
            XCTAssertEqual(classification.category, .other, path)
            XCTAssertEqual(classification.protection, .requiresReview, path)
        }
    }
}
