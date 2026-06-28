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

    func testSelectMovableCandidatesSkipsBlockedItems() {
        let safe = candidate(path: "/tmp/a.cache", size: 10, category: .cache, protection: .allowed)
        let review = candidate(path: "/Users/me/Downloads/app.dmg", size: 20, category: .downloads, protection: .requiresReview)
        let blocked = candidate(path: "/System/Library/do-not-touch", size: 30, category: .other, protection: .blocked)
        var selection = CleaningSelection()

        selection.selectMovable([safe, review, blocked])

        XCTAssertTrue(selection.contains(safe))
        XCTAssertTrue(selection.contains(review))
        XCTAssertFalse(selection.contains(blocked))
        XCTAssertEqual(selection.summary(for: [safe, review, blocked]).selectedCount, 2)
    }

    func testSelectDuplicateCopiesSelectsOnlyMovableCopiesAndPreservesOneOriginal() {
        let original = candidate(
            path: "/tmp/new.txt",
            size: 10,
            category: .other,
            modifiedAt: Date(timeIntervalSince1970: 2),
            protection: .allowed
        )
        let duplicate = candidate(
            path: "/tmp/old.txt",
            size: 10,
            category: .other,
            modifiedAt: Date(timeIntervalSince1970: 1),
            protection: .allowed
        )
        let blocked = candidate(
            path: "/System/copy.txt",
            size: 10,
            category: .other,
            modifiedAt: Date(timeIntervalSince1970: 0),
            protection: .blocked
        )
        let group = DuplicateFileGroup(contentHash: "hash", sizeBytes: 10, candidates: [duplicate, original, blocked])
        var selection = CleaningSelection()

        selection.selectDuplicateCopies(in: [group])

        XCTAssertTrue(selection.contains(duplicate))
        XCTAssertFalse(selection.contains(original))
        XCTAssertFalse(selection.contains(blocked))
    }

    private func candidate(
        path: String,
        size: Int64,
        category: CandidateCategory,
        modifiedAt: Date = Date(timeIntervalSince1970: 0),
        protection: DeletionProtection = .requiresReview
    ) -> CleaningCandidate {
        CleaningCandidate(
            url: URL(filePath: path),
            sizeBytes: size,
            modifiedAt: modifiedAt,
            category: category,
            risk: .reviewRecommended,
            reasons: [],
            isDirectory: false,
            protection: protection,
            ruleMatches: [],
            userVisibleRules: []
        )
    }
}
