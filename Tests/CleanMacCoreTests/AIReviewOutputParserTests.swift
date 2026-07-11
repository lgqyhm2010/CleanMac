import XCTest
@testable import CleanMacCore

final class AIReviewOutputParserTests: XCTestCase {
    func testMapsAnonymousItemIDsBackToLocalPaths() throws {
        let raw = #"{"summary":"ok","safe_to_delete":[{"item_id":"item-0001","reason":"cache"}],"risky":[],"needs_user_review":[]}"#

        let parsed = try XCTUnwrap(AIReviewOutputParser.parse(
            raw,
            itemPathsByID: ["item-0001": "/Users/me/Library/Caches/a"]
        ))

        XCTAssertEqual(parsed.safeToDelete.first?.path, "/Users/me/Library/Caches/a")
    }

    func testParsesCleanSchemaJSON() throws {
        let raw = """
        {"summary": "Mostly caches, one document needs review.",
         "safe_to_delete": [{"path": "/Users/me/Library/Caches/a", "reason": "regenerable cache"}],
         "risky": [{"path": "/Users/me/Documents/thesis.docx", "reason": "personal document"}],
         "needs_user_review": [{"path": "/Users/me/Downloads/setup.dmg", "reason": "unclear origin"}]}
        """

        let parsed = try XCTUnwrap(AIReviewOutputParser.parse(raw))

        XCTAssertEqual(parsed.summary, "Mostly caches, one document needs review.")
        XCTAssertEqual(parsed.safeToDelete, [AIReviewItem(path: "/Users/me/Library/Caches/a", reason: "regenerable cache")])
        XCTAssertEqual(parsed.risky.map(\.path), ["/Users/me/Documents/thesis.docx"])
        XCTAssertEqual(parsed.needsUserReview.map(\.reason), ["unclear origin"])
    }

    func testParsesJSONWrappedInMarkdownFences() throws {
        let raw = """
        Here is my assessment:
        ```json
        {"summary": "ok", "safe_to_delete": [{"path": "/tmp/a", "reason": "temp"}], "risky": [], "needs_user_review": []}
        ```
        """

        let parsed = try XCTUnwrap(AIReviewOutputParser.parse(raw))

        XCTAssertEqual(parsed.summary, "ok")
        XCTAssertEqual(parsed.safeToDelete.map(\.path), ["/tmp/a"])
        XCTAssertTrue(parsed.risky.isEmpty)
    }

    func testParsesJSONEmbeddedInProse() throws {
        let raw = """
        Based on the candidates, my analysis follows.
        {"summary": "one cache", "safe_to_delete": ["/tmp/cache.bin"], "risky": [], "needs_user_review": []}
        Let me know if you need more detail.
        """

        let parsed = try XCTUnwrap(AIReviewOutputParser.parse(raw))

        // String elements are accepted as bare paths with no reason.
        XCTAssertEqual(parsed.safeToDelete, [AIReviewItem(path: "/tmp/cache.bin", reason: nil)])
    }

    func testAcceptsAlternateObjectKeys() throws {
        let raw = """
        {"summary": "alt keys", "safe_to_delete": [{"file": "/tmp/x", "note": "leftover"}],
         "risky": [{"url": "/tmp/y", "why": "unknown"}], "needs_user_review": []}
        """

        let parsed = try XCTUnwrap(AIReviewOutputParser.parse(raw))

        XCTAssertEqual(parsed.safeToDelete, [AIReviewItem(path: "/tmp/x", reason: "leftover")])
        XCTAssertEqual(parsed.risky, [AIReviewItem(path: "/tmp/y", reason: "unknown")])
    }

    func testParsesRealCodexOutputSample() throws {
        // Captured verbatim from `codex exec` (gpt-5.5, 2026-07-04) fed the app's
        // tightened schema prompt — the canonical happy path.
        let raw = """
        {"summary":"整体看，Xcode DerivedData 旧构建缓存通常可以移到废纸篓，代价只是之后可能需要重新构建；但 thesis-final.docx 是个人文档且文件名像最终论文，即使位于“项目备份”目录，也不建议直接删，应先确认已有其他备份或内容不再需要。","safe_to_delete":[{"path":"/Users/me/Library/Caches/com.apple.dt.Xcode/DerivedData/old-build","reason":"Xcode 派生构建缓存，可重新生成，移到废纸篓通常安全。"}],"risky":[],"needs_user_review":[{"path":"/Users/me/Documents/项目备份/thesis-final.docx","reason":"个人文档/论文最终版，删除前应打开确认内容并确认已有备份。"}]}
        """

        let parsed = try XCTUnwrap(AIReviewOutputParser.parse(raw))

        XCTAssertTrue(parsed.summary?.contains("DerivedData") ?? false)
        XCTAssertEqual(parsed.safeToDelete.count, 1)
        XCTAssertTrue(parsed.risky.isEmpty)
        XCTAssertEqual(parsed.needsUserReview.map(\.path), ["/Users/me/Documents/项目备份/thesis-final.docx"])
    }

    func testReturnsNilForPureProse() {
        XCTAssertNil(AIReviewOutputParser.parse("I could not produce a structured answer, sorry."))
    }

    func testReturnsNilWhenEverythingIsEmpty() {
        XCTAssertNil(AIReviewOutputParser.parse("{\"safe_to_delete\": [], \"risky\": [], \"needs_user_review\": []}"))
    }

    func testReturnsNilForEmptyInput() {
        XCTAssertNil(AIReviewOutputParser.parse(""))
        XCTAssertNil(AIReviewOutputParser.parse("   \n"))
    }
}
