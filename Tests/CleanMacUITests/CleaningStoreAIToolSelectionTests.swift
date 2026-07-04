import CleanMacCore
import XCTest
@testable import CleanMac

@MainActor
final class CleaningStoreAIToolSelectionTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "aiSelectedToolID")
        UserDefaults.standard.removeObject(forKey: "aiModelPreferenceByTool")
        super.tearDown()
    }

    func testSelectedModelDefaultsToTheFirstOptionAndFallsBackOnUnknownID() {
        let store = makeStore(found: ["claude": "/a/claude"])

        XCTAssertEqual(store.selectedModelOption(for: "claude"), .default)

        store.selectModel("no-such-model", for: "claude")
        XCTAssertEqual(store.selectedModelOption(for: "claude"), .default, "unknown ids fall back to Default")
    }

    func testSelectedModelPersistsPerToolAcrossRelaunch() {
        let first = makeStore(found: ["claude": "/a/claude", "codex": "/a/codex"])
        first.selectModel("opus", for: "claude")
        first.selectModel("gpt-5.4", for: "codex")

        let second = makeStore(found: ["claude": "/a/claude", "codex": "/a/codex"])

        XCTAssertEqual(second.selectedModelOption(for: "claude")?.id, "opus")
        XCTAssertEqual(second.selectedModelOption(for: "codex")?.id, "gpt-5.4")
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

    func testPreparingAIReviewScreenClearsErrorBledOverFromOtherScreensAndDetectsTools() async {
        let store = makeStore(found: ["codex": "/opt/homebrew/bin/codex"])
        // An error raised on a different screen (e.g. the Cleaner) must not linger on the
        // AI Review screen when the user navigates to it.
        store.errorMessage = .system("scan failed on another screen")

        await store.prepareAIReviewScreen()

        XCTAssertNil(store.errorMessage, "entering the AI Review screen clears stale cross-screen errors")
        XCTAssertEqual(store.detectedAITools.map(\.id), ["codex"], "entering the screen refreshes the detected tools")
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
