import XCTest
@testable import CleanMacCore

final class AIToolDetectorTests: XCTestCase {
    func testDetectsOnlyToolsWhoseBinaryIsFound() {
        let locator = FakeExecutableLocator(found: ["codex": "/opt/homebrew/bin/codex"])
        let detector = AIToolDetector(locator: locator)

        let detected = detector.detectAvailableTools()

        XCTAssertEqual(detected.map(\.id), ["codex"])
        XCTAssertEqual(detected.first?.executablePath, "/opt/homebrew/bin/codex")
    }

    func testDetectsMultipleToolsInProfileOrder() {
        let locator = FakeExecutableLocator(found: [
            "codex": "/opt/homebrew/bin/codex",
            "gemini": "/opt/homebrew/bin/gemini"
        ])
        let detector = AIToolDetector(locator: locator)

        XCTAssertEqual(detector.detectAvailableTools().map(\.id), ["codex", "gemini"])
    }

    func testReturnsEmptyWhenNoKnownToolIsFound() {
        let detector = AIToolDetector(locator: FakeExecutableLocator(found: [:]))

        XCTAssertTrue(detector.detectAvailableTools().isEmpty)
    }

    func testKnownProfilesUseCorrectPromptDeliveryPerTool() {
        let profiles = Dictionary(uniqueKeysWithValues: AIToolProfile.knownProfiles.map { ($0.id, $0) })

        XCTAssertEqual(profiles["codex"]?.promptDelivery, .standardInput)
        XCTAssertEqual(profiles["claude"]?.promptDelivery, .standardInput)
        XCTAssertEqual(profiles["gemini"]?.promptDelivery, .argument)
    }
}

private struct FakeExecutableLocator: ExecutableLocating {
    let found: [String: String]

    func locate(_ binaryName: String) -> String? {
        found[binaryName]
    }
}
