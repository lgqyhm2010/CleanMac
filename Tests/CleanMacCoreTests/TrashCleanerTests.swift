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
    }

    private func candidate(path: String, size: Int64) -> CleaningCandidate {
        CleaningCandidate(
            url: URL(filePath: path),
            sizeBytes: size,
            modifiedAt: nil,
            category: .cache,
            risk: .usuallySafe,
            reasons: [],
            isDirectory: false
        )
    }
}

private final class RecordingFileTrasher: FileTrashing {
    private(set) var urls: [URL] = []

    func trashItem(at url: URL) throws {
        urls.append(url)
    }
}
