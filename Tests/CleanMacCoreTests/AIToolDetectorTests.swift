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

    // Exercises the REAL PATHExecutableLocator logic (not a fake) — the load-bearing
    // resolution that determines whether any tool is ever found in the shipped app.
    func testLocatesRealExecutableFileAndRejectsDirectoriesAndMissingNames() throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory.appending(path: "cleanmac-locator-\(UUID().uuidString)")
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directory) }

        let codex = directory.appending(path: "codex")
        try Data("#!/bin/sh\n".utf8).write(to: codex)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: codex.path)
        // A *directory* named like a tool must not be reported as a launchable executable.
        try fileManager.createDirectory(at: directory.appending(path: "claude"), withIntermediateDirectories: true)

        let locator = PATHExecutableLocator(searchDirectories: [directory.path])

        XCTAssertEqual(locator.locate("codex"), codex.path)
        XCTAssertNil(locator.locate("claude"), "a directory must not be treated as an executable")
        XCTAssertNil(locator.locate("gemini"), "an absent binary resolves to nil")
    }

    func testSearchDirectoriesUnionInheritedPATHWithWellKnownDirsDedupedAndAbsoluteOnly() {
        let directories = ExecutableSearchPath.directories(
            environmentPATH: "/usr/bin::relative/bin:/opt/homebrew/bin",
            homeDirectory: "/Users/tester"
        )

        XCTAssertEqual(directories.first, "/usr/bin", "inherited PATH entries come first, in order")
        XCTAssertTrue(directories.contains("/opt/homebrew/bin"))
        XCTAssertTrue(directories.contains("/Users/tester/.local/bin"), "well-known dirs are appended, resolved against homeDirectory")
        XCTAssertFalse(directories.contains(""), "empty PATH entries are dropped")
        XCTAssertFalse(directories.contains("relative/bin"), "relative entries are dropped so nothing resolves against the cwd")
        XCTAssertEqual(directories.count, Set(directories).count, "no duplicate directories")
        XCTAssertEqual(directories.filter { $0 == "/opt/homebrew/bin" }.count, 1, "an inherited dir also in the well-known list appears once")
    }
}

private struct FakeExecutableLocator: ExecutableLocating {
    let found: [String: String]

    func locate(_ binaryName: String) -> String? {
        found[binaryName]
    }
}
