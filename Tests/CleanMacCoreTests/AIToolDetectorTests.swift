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
            "gemini": "/opt/homebrew/bin/gemini",
            "agy": "/opt/homebrew/bin/agy"
        ])
        let detector = AIToolDetector(locator: locator)

        XCTAssertEqual(detector.detectAvailableTools().map(\.id), ["codex", "gemini", "antigravity"])
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
        XCTAssertEqual(profiles["antigravity"]?.promptDelivery, .argument)
    }

    func testKnownProfilesExposeDefaultFirstModelOptions() {
        for profile in AIToolProfile.knownProfiles {
            XCTAssertEqual(profile.modelOptions.first, .default, "\(profile.id) must offer Default first")
            XCTAssertGreaterThan(profile.modelOptions.count, 1, "\(profile.id) must offer real models")
        }
    }

    func testKnownProfilesUseEachCLIsModelFlag() {
        let flags = Dictionary(uniqueKeysWithValues: AIToolProfile.knownProfiles.map { ($0.id, $0.modelFlag) })
        XCTAssertEqual(flags["claude"], "--model")
        XCTAssertEqual(flags["codex"], "-m")
        XCTAssertEqual(flags["gemini"], "-m")
        XCTAssertEqual(flags["antigravity"], "--model")
    }

    func testClaudeModelOptionsUseAliases() {
        // Official aliases auto-upgrade to the newest generation (code.claude.com/docs/en/model-config).
        let claude = AIToolProfile.knownProfiles.first { $0.id == "claude" }
        XCTAssertEqual(claude?.modelOptions.compactMap(\.flagValue), ["fable", "opus", "sonnet", "haiku"])
    }

    func testCodexModelOptionsUseCurrentIDs() {
        // codex has no alias mechanism; IDs verified against developers.openai.com/codex/models
        // (July 2026: gpt-5.5 default flagship, gpt-5.4 fallback, gpt-5.4-mini light).
        let codex = AIToolProfile.knownProfiles.first { $0.id == "codex" }
        XCTAssertEqual(codex?.modelOptions.compactMap(\.flagValue), ["gpt-5.5", "gpt-5.4", "gpt-5.4-mini"])
    }

    func testGeminiModelOptionsUseStableAliases() {
        // geminicli.com/docs/cli/model: `pro`/`flash` aliases route to the current
        // generation, unlike pinned `-preview` ids that break when models GA.
        let gemini = AIToolProfile.knownProfiles.first { $0.id == "gemini" }
        XCTAssertEqual(gemini?.modelOptions.compactMap(\.flagValue), ["pro", "flash"])
    }

    func testAntigravityRunsHeadlessPrintModeWithPromptDirectlyAfterDashP() {
        // agy's `-p` takes the prompt as the flag's own argument value, so "-p" must be
        // the LAST base argument — AIReviewService appends the prompt right after it.
        // `--print-timeout 20m` lifts print mode's 5m default, which a long review with
        // a thinking model can exceed.
        let antigravity = AIToolProfile.knownProfiles.first { $0.id == "antigravity" }
        XCTAssertEqual(antigravity?.binaryName, "agy")
        XCTAssertEqual(antigravity?.arguments, ["--print-timeout", "20m", "-p"])
        XCTAssertEqual(antigravity?.displayName, "Antigravity CLI")
    }

    func testAntigravityModelOptionsUseCurrentIDs() {
        // agy has no alias mechanism; ids follow the Switch Model screen scheme
        // (gemini-3.1-pro / claude-opus-4-6 style, agy 1.0.x, July 2026) and need
        // refreshing when Google rotates the lineup. Default = agy auto-selection.
        let antigravity = AIToolProfile.knownProfiles.first { $0.id == "antigravity" }
        XCTAssertEqual(
            antigravity?.modelOptions.compactMap(\.flagValue),
            ["gemini-3.5-flash", "gemini-3.1-pro", "claude-sonnet-4-6", "claude-opus-4-6"]
        )
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
