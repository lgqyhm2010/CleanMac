import XCTest
@testable import CleanMacCore

final class TrashCleanerTests: XCTestCase {
    func testCleanerMovesCandidatesToTrashAndReportsReclaimedBytes() throws {
        let trasher = RecordingFileTrasher()
        let cleaner = TrashCleaner(trasher: trasher)
        let candidates = [
            candidate(path: "/tmp/a.cache", size: 10),
            candidate(path: "/tmp/b.log", size: 20)
        ]

        let result = try cleaner.clean(candidates)

        XCTAssertEqual(trasher.urls, candidates.map(\.url))
        XCTAssertEqual(result.cleanedCount, 2)
        XCTAssertEqual(result.reclaimedBytes, 30)
        XCTAssertTrue(result.failures.isEmpty)
        XCTAssertTrue(result.skipped.isEmpty)
    }

    func testCleanerDoesNotTrashBlockedCandidates() throws {
        let trasher = RecordingFileTrasher()
        let cleaner = TrashCleaner(trasher: trasher)
        let safe = candidate(path: "/tmp/a.cache", size: 10, protection: .allowed)
        let blocked = candidate(path: "/System/Library/do-not-touch", size: 20, protection: .blocked)

        let result = try cleaner.clean([safe, blocked])

        XCTAssertEqual(trasher.urls, [safe.url])
        XCTAssertEqual(result.cleanedCount, 1)
        XCTAssertEqual(result.reclaimedBytes, 10)
        XCTAssertTrue(result.failures.isEmpty)
        XCTAssertEqual(result.skipped.count, 1)
        XCTAssertEqual(result.skipped.first?.url, blocked.url)
        XCTAssertTrue(result.skipped.first?.message.localizedCaseInsensitiveContains("protected") == true)
    }

    private func candidate(
        path: String,
        size: Int64,
        protection: DeletionProtection = .allowed
    ) -> CleaningCandidate {
        CleaningCandidate(
            url: URL(filePath: path),
            sizeBytes: size,
            modifiedAt: nil,
            category: .cache,
            risk: .usuallySafe,
            reasons: [],
            isDirectory: false,
            protection: protection,
            ruleMatches: [],
            userVisibleRules: []
        )
    }
}

private final class RecordingFileTrasher: FileTrashing {
    private(set) var urls: [URL] = []

    func trashItem(at url: URL) throws {
        urls.append(url)
    }
}
