import CleanMacCore
import XCTest
@testable import CleanMac

final class DefaultScanRootsTests: XCTestCase {
    /// A seeded root that `ScanClassifier` does not recognize falls through to `.other`,
    /// where `SafetyRuleEngine` blocks its directories outright — the folder would fill
    /// the results list with items the user can never act on.
    func testEveryDefaultRootIsARecognizedNonBlockedLocation() {
        let classifier = ScanClassifier()

        for root in DefaultScanRoots.urls {
            let classification = classifier.classify(url: root, sizeBytes: 0, isDirectory: true)

            XCTAssertNotEqual(
                classification.category,
                .other,
                "ScanClassifier does not recognize \(root.path)"
            )
            XCTAssertNotEqual(
                classification.protection,
                .blocked,
                "\(root.path) would only ever list items the user cannot clean"
            )
        }
    }

    func testDefaultRootsSeedEveryCommonCleanupFolderThatExists() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let urls = DefaultScanRoots.urls

        let expected = [
            ".Trash",
            "Downloads",
            "Library/Caches",
            "Library/Logs",
            "Library/Developer/Xcode/DerivedData",
            "Library/Developer/Xcode/iOS DeviceSupport"
        ]
        for path in expected {
            let url = home.appending(path: path, directoryHint: .isDirectory)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            XCTAssertTrue(urls.contains(url), "\(path) exists on disk but is not seeded")
        }

        // CoreSimulator's ~1M files would dominate scan time for candidates that cannot be
        // safely deleted one by one, so it must stay off the default list.
        XCTAssertFalse(
            urls.contains { $0.path.contains("CoreSimulator") },
            "CoreSimulator must not be seeded by default"
        )

        XCTAssertEqual(Set(urls.map(\.path)).count, urls.count, "Seeded roots contain a duplicate")
        XCTAssertTrue(urls.allSatisfy { FileManager.default.fileExists(atPath: $0.path) })
    }
}
