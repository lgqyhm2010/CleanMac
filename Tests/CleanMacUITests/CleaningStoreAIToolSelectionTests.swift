import CleanMacCore
import XCTest
@testable import CleanMac

@MainActor
final class CleaningStoreAIToolSelectionTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "aiSelectedToolID")
        super.tearDown()
    }

    func testRefreshDetectedAIToolsAutoSelectsTheOnlyDetectedTool() {
        let store = makeStore(found: ["codex": "/opt/homebrew/bin/codex"])

        XCTAssertEqual(store.detectedAITools.map(\.id), ["codex"])
        XCTAssertEqual(store.selectedAIToolID, "codex")
    }

    func testRefreshDetectedAIToolsLeavesSelectionNilWhenMultipleFoundAndNoPriorChoice() {
        let store = makeStore(found: ["codex": "/a/codex", "claude": "/a/claude"])

        XCTAssertNil(store.selectedAIToolID)
    }

    func testSelectedToolPersistsAcrossAppRelaunch() {
        let first = makeStore(found: ["codex": "/a/codex", "claude": "/a/claude"])
        first.selectAITool("claude")

        let second = makeStore(found: ["codex": "/a/codex", "claude": "/a/claude"])

        XCTAssertEqual(second.selectedAIToolID, "claude")
    }

    func testAskAISetsNoAIToolDetectedErrorWhenNothingIsAvailable() {
        let store = makeStore(found: [:])
        store.candidates = [sampleCandidate()]
        store.selection.selectMovable(store.candidates)

        store.askAI()

        XCTAssertEqual(store.errorMessage, .noAIToolDetected)
    }

    private func makeStore(found: [String: String]) -> CleaningStore {
        CleaningStore(
            language: .english,
            aiToolDetector: AIToolDetector(locator: FakeExecutableLocator(found: found))
        )
    }

    private func sampleCandidate() -> CleaningCandidate {
        CleaningCandidate(
            url: URL(filePath: "/tmp/cache.bin"),
            sizeBytes: 64,
            modifiedAt: nil,
            category: .cache,
            risk: .usuallySafe,
            reasons: ["Cache file"],
            isDirectory: false
        )
    }
}

private struct FakeExecutableLocator: ExecutableLocating {
    let found: [String: String]

    func locate(_ binaryName: String) -> String? {
        found[binaryName]
    }
}
