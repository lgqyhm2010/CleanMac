import XCTest
@testable import CleanMacCore

final class CleaningSelectionTests: XCTestCase {
    func testSummaryTotalsSelectedCandidatesByCategory() {
        let candidates = [
            candidate(path: "/tmp/a.cache", size: 10, category: .cache),
            candidate(path: "/tmp/b.log", size: 20, category: .logs),
            candidate(path: "/tmp/c.mov", size: 30, category: .largeFile)
        ]
        var selection = CleaningSelection()

        selection.toggle(candidates[0])
        selection.toggle(candidates[2])

        let summary = selection.summary(for: candidates)
        XCTAssertEqual(summary.selectedCount, 2)
        XCTAssertEqual(summary.totalBytes, 40)
        XCTAssertEqual(summary.countsByCategory[.cache], 1)
        XCTAssertEqual(summary.countsByCategory[.largeFile], 1)

        selection.toggle(candidates[0])
        XCTAssertEqual(selection.summary(for: candidates).selectedCount, 1)
    }

    private func candidate(path: String, size: Int64, category: CandidateCategory) -> CleaningCandidate {
        CleaningCandidate(
            url: URL(filePath: path),
            sizeBytes: size,
            modifiedAt: Date(timeIntervalSince1970: 0),
            category: category,
            risk: .reviewRecommended,
            reasons: [],
            isDirectory: false
        )
    }
}
