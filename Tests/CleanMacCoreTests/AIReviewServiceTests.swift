import XCTest
@testable import CleanMacCore

final class AIReviewServiceTests: XCTestCase {
    func testPromptIncludesCandidateContextAndUserQuestion() {
        let service = AIReviewService(
            tool: DetectedAITool(
                profile: AIToolProfile(id: "test", displayName: "Test", binaryName: "test-ai", arguments: ["--quiet"], promptDelivery: .standardInput),
                executablePath: "/usr/bin/ai"
            ),
            runner: RecordingCommandRunner()
        )
        let prompt = service.makePrompt(
            candidates: [
                CleaningCandidate(
                    url: URL(filePath: "/Users/me/Downloads/old-installer.dmg"),
                    sizeBytes: 12_345,
                    modifiedAt: Date(timeIntervalSince1970: 1_700_000_000),
                    category: .downloads,
                    risk: .reviewRecommended,
                    reasons: ["Downloads folder item"],
                    isDirectory: false
                )
            ],
            userQuestion: "这个可以删吗？"
        )

        XCTAssertTrue(prompt.contains("old-installer.dmg"))
        XCTAssertTrue(prompt.contains("Downloads folder item"))
        XCTAssertTrue(prompt.contains("protection:"))
        XCTAssertTrue(prompt.contains("rules:"))
        XCTAssertTrue(prompt.contains("这个可以删吗？"))
        XCTAssertTrue(prompt.contains("JSON"))
    }

    func testPromptPinsTheExactResponseSchema() {
        // AIReviewOutputParser depends on this schema; the prompt must pin element
        // shape and forbid markdown fences so parsing succeeds without heuristics.
        let service = AIReviewService(
            tool: DetectedAITool(
                profile: AIToolProfile.knownProfiles.first { $0.id == "claude" }!,
                executablePath: "/usr/bin/ai"
            ),
            runner: RecordingCommandRunner()
        )

        let prompt = service.makePrompt(candidates: [sampleCandidate()], userQuestion: "safe?")

        XCTAssertTrue(prompt.contains("no markdown fences"), "prompt must forbid code fences")
        XCTAssertTrue(prompt.contains("\"safe_to_delete\": [{\"path\""), "prompt must pin the element object shape")
        XCTAssertTrue(prompt.contains("\"needs_user_review\""))
    }

    func testReviewSendsPromptViaStandardInputWhenToolUsesStandardInputDelivery() async throws {
        let runner = RecordingCommandRunner()
        let tool = DetectedAITool(
            profile: AIToolProfile(id: "codex", displayName: "Codex", binaryName: "codex", arguments: ["exec"], promptDelivery: .standardInput),
            executablePath: "/usr/bin/ai"
        )
        let service = AIReviewService(tool: tool, runner: runner)
        let candidate = CleaningCandidate(
            url: URL(filePath: "/tmp/cache.bin"),
            sizeBytes: 64,
            modifiedAt: nil,
            category: .cache,
            risk: .usuallySafe,
            reasons: ["Cache file"],
            isDirectory: false
        )

        let review = try await service.review(candidates: [candidate], userQuestion: "safe?")

        XCTAssertEqual(review.output, "safe to remove")
        XCTAssertEqual(runner.commands.count, 1)
        XCTAssertEqual(runner.commands[0].executable, "/usr/bin/ai")
        XCTAssertEqual(runner.commands[0].arguments, ["exec"])
        XCTAssertNotNil(runner.commands[0].environment, "review() must set the child environment")
        XCTAssertEqual(runner.standardInputs.count, 1)
        XCTAssertTrue(runner.standardInputs[0].contains("/tmp/cache.bin"))
    }

    func testReviewAppendsPromptAsArgumentWhenToolUsesArgumentDelivery() async throws {
        let runner = RecordingCommandRunner()
        let tool = DetectedAITool(
            profile: AIToolProfile(id: "gemini", displayName: "Gemini CLI", binaryName: "gemini", arguments: ["-p"], promptDelivery: .argument),
            executablePath: "/usr/bin/ai"
        )
        let service = AIReviewService(tool: tool, runner: runner)
        let candidate = CleaningCandidate(
            url: URL(filePath: "/tmp/cache.bin"),
            sizeBytes: 64,
            modifiedAt: nil,
            category: .cache,
            risk: .usuallySafe,
            reasons: ["Cache file"],
            isDirectory: false
        )

        _ = try await service.review(candidates: [candidate], userQuestion: "safe?")

        XCTAssertEqual(runner.commands.count, 1)
        XCTAssertEqual(runner.commands[0].executable, "/usr/bin/ai")
        XCTAssertEqual(runner.commands[0].arguments.first, "-p")
        XCTAssertTrue(runner.commands[0].arguments.last?.contains("/tmp/cache.bin") ?? false)
        XCTAssertEqual(runner.standardInputs, [""])
    }

    func testReviewGivesTheChildAnAugmentedPATHSoHomebrewToolsResolve() async throws {
        // A Finder/Dock-launched app inherits launchd's minimal PATH, which omits the
        // Homebrew dir that codex/gemini — and the `node` their shebangs exec — live in.
        // review() must hand the spawned process a PATH that includes those locations.
        let runner = RecordingCommandRunner()
        let tool = DetectedAITool(
            profile: AIToolProfile(id: "codex", displayName: "Codex", binaryName: "codex", arguments: ["exec"], promptDelivery: .standardInput),
            executablePath: "/opt/homebrew/bin/codex"
        )
        let service = AIReviewService(tool: tool, runner: runner)
        let candidate = CleaningCandidate(
            url: URL(filePath: "/tmp/cache.bin"),
            sizeBytes: 64,
            modifiedAt: nil,
            category: .cache,
            risk: .usuallySafe,
            reasons: ["Cache file"],
            isDirectory: false
        )

        _ = try await service.review(candidates: [candidate], userQuestion: "safe?")

        let environment = try XCTUnwrap(runner.commands.first?.environment)
        let searchDirs = try XCTUnwrap(environment["PATH"]).split(separator: ":").map(String.init)
        XCTAssertTrue(
            searchDirs.contains("/opt/homebrew/bin"),
            "child PATH must include Homebrew so `env node` resolves; got: \(searchDirs)"
        )
    }

    func testReviewThrowsErrorDescribingWhyTheCommandFailed() async {
        let runner = FailingCommandRunner(
            exitCode: 1,
            standardError: "Error loading config.toml: unknown variant `default`, expected `fast` or `flex` in `service_tier`",
            standardOutput: ""
        )
        let tool = DetectedAITool(
            profile: AIToolProfile(id: "codex", displayName: "Codex", binaryName: "codex", arguments: ["exec"], promptDelivery: .standardInput),
            executablePath: "/usr/bin/env"
        )
        let service = AIReviewService(tool: tool, runner: runner)
        let candidate = CleaningCandidate(
            url: URL(filePath: "/tmp/cache.bin"),
            sizeBytes: 64,
            modifiedAt: nil,
            category: .cache,
            risk: .usuallySafe,
            reasons: ["Cache file"],
            isDirectory: false
        )

        do {
            _ = try await service.review(candidates: [candidate], userQuestion: "safe?")
            XCTFail("expected review to throw")
        } catch {
            let description = error.localizedDescription
            XCTAssertTrue(
                description.contains("service_tier"),
                "error shown to the user should include the AI command's actual stderr, got: \(description)"
            )
        }
    }

    func testReviewAppendsModelFlagAfterBaseArgumentsForStdinTools() async throws {
        let runner = RecordingCommandRunner()
        let profile = AIToolProfile.knownProfiles.first { $0.id == "codex" }!
        let tool = DetectedAITool(profile: profile, executablePath: "/usr/bin/ai")
        let service = AIReviewService(tool: tool, runner: runner)
        let model = AIModelOption(id: "gpt-5.1", displayName: "gpt-5.1", flagValue: "gpt-5.1")

        _ = try await service.review(candidates: [sampleCandidate()], userQuestion: "safe?", model: model)

        XCTAssertEqual(runner.commands[0].arguments, ["exec", "-m", "gpt-5.1"])
    }

    func testReviewInsertsModelFlagBeforeBaseArgumentsForArgumentTools() async throws {
        // gemini's prompt must directly follow -p, so the model pair goes first: -m X -p <prompt>
        let runner = RecordingCommandRunner()
        let profile = AIToolProfile.knownProfiles.first { $0.id == "gemini" }!
        let tool = DetectedAITool(profile: profile, executablePath: "/usr/bin/ai")
        let service = AIReviewService(tool: tool, runner: runner)
        let model = AIModelOption(id: "gemini-2.5-pro", displayName: "gemini-2.5-pro", flagValue: "gemini-2.5-pro")

        _ = try await service.review(candidates: [sampleCandidate()], userQuestion: "safe?", model: model)

        let arguments = runner.commands[0].arguments
        XCTAssertEqual(Array(arguments.prefix(3)), ["-m", "gemini-2.5-pro", "-p"])
        XCTAssertTrue(arguments.last?.contains("safe?") ?? false)
    }

    func testReviewOmitsModelFlagForDefaultAndNilModel() async throws {
        let runner = RecordingCommandRunner()
        let profile = AIToolProfile.knownProfiles.first { $0.id == "claude" }!
        let tool = DetectedAITool(profile: profile, executablePath: "/usr/bin/ai")
        let service = AIReviewService(tool: tool, runner: runner)

        _ = try await service.review(candidates: [sampleCandidate()], userQuestion: "safe?", model: .default)
        _ = try await service.review(candidates: [sampleCandidate()], userQuestion: "safe?")

        XCTAssertEqual(runner.commands[0].arguments, ["-p"])
        XCTAssertEqual(runner.commands[1].arguments, ["-p"])
    }

    func testCommandFailedErrorKeepsTheTailOfLongOutputBounded() {
        // codex exec streams its whole transcript to stdout before a non-zero exit; the
        // error label in AIReviewView renders errorDescription verbatim, so an unbounded
        // detail would crush the layout. Keep the tail — CLIs print the fatal line last.
        let longOutput = String(repeating: "x", count: 10_000) + "\nFATAL: the actual reason"
        let error = AIReviewError.commandFailed(exitCode: 1, standardError: "", standardOutput: longOutput)

        let description = error.localizedDescription

        XCTAssertLessThan(description.count, 1_000, "error surfaced to the UI must stay bounded")
        XCTAssertTrue(description.contains("FATAL: the actual reason"), "the fatal tail must survive truncation, got: \(description.suffix(80))")
    }

    func testChildEnvironmentStripsNestedClaudeSessionMarkersButKeepsUserConfig() {
        // If CleanMac itself was launched from a Claude Code session (common during
        // development), the child `claude` would inherit the session markers and
        // misdetect a nested session. User-facing config such as ANTHROPIC_BASE_URL
        // must survive — proxy users rely on it.
        let base = [
            "CLAUDECODE": "1",
            "CLAUDE_CODE_ENTRYPOINT": "cli",
            "CLAUDE_CODE_EXECPATH": "/somewhere/claude",
            "CLAUDE_CODE_SESSION_ID": "abc",
            "CLAUDE_CODE_SSE_PORT": "1234",
            "ANTHROPIC_BASE_URL": "https://proxy.example.com",
            "HOME": "/Users/me"
        ]

        let child = AIReviewService.childEnvironment(from: base)

        XCTAssertNil(child["CLAUDECODE"])
        XCTAssertNil(child["CLAUDE_CODE_ENTRYPOINT"])
        XCTAssertNil(child["CLAUDE_CODE_EXECPATH"])
        XCTAssertNil(child["CLAUDE_CODE_SESSION_ID"])
        XCTAssertNil(child["CLAUDE_CODE_SSE_PORT"])
        XCTAssertEqual(child["ANTHROPIC_BASE_URL"], "https://proxy.example.com")
        XCTAssertEqual(child["HOME"], "/Users/me")
        XCTAssertNotNil(child["PATH"], "childEnvironment must install the augmented PATH")
    }

    func testReviewErrorIncludesStandardOutputWhenStderrIsEmpty() async {
        // claude prints fatal errors like "Not logged in · Please run /login" to stdout
        // and exits 1 with an empty stderr. Surfacing only stderr would collapse the
        // actionable message into "no output".
        let runner = FailingCommandRunner(
            exitCode: 1,
            standardError: "",
            standardOutput: "Not logged in · Please run /login"
        )
        let tool = DetectedAITool(
            profile: AIToolProfile(id: "claude", displayName: "Claude Code", binaryName: "claude", arguments: ["-p"], promptDelivery: .standardInput),
            executablePath: "/usr/bin/env"
        )
        let service = AIReviewService(tool: tool, runner: runner)
        let candidate = CleaningCandidate(
            url: URL(filePath: "/tmp/cache.bin"),
            sizeBytes: 64,
            modifiedAt: nil,
            category: .cache,
            risk: .usuallySafe,
            reasons: ["Cache file"],
            isDirectory: false
        )

        do {
            _ = try await service.review(candidates: [candidate], userQuestion: "safe?")
            XCTFail("expected review to throw")
        } catch {
            let description = error.localizedDescription
            XCTAssertTrue(
                description.contains("Not logged in"),
                "error shown to the user should fall back to the AI command's stdout, got: \(description)"
            )
        }
    }
}

private func sampleCandidate() -> CleaningCandidate {
    CleaningCandidate(
        url: URL(filePath: "/tmp/cache.bin"), sizeBytes: 64, modifiedAt: nil,
        category: .cache, risk: .usuallySafe, reasons: ["Cache file"], isDirectory: false
    )
}

private final class RecordingCommandRunner: CommandRunning {
    private(set) var commands: [AICommand] = []
    private(set) var standardInputs: [String] = []

    func run(command: AICommand, standardInput: String) async throws -> CommandResult {
        commands.append(command)
        standardInputs.append(standardInput)
        return CommandResult(exitCode: 0, standardOutput: "safe to remove", standardError: "")
    }
}

private final class FailingCommandRunner: CommandRunning {
    private let exitCode: Int32
    private let standardError: String
    private let standardOutput: String

    init(exitCode: Int32, standardError: String, standardOutput: String) {
        self.exitCode = exitCode
        self.standardError = standardError
        self.standardOutput = standardOutput
    }

    func run(command: AICommand, standardInput: String) async throws -> CommandResult {
        CommandResult(exitCode: exitCode, standardOutput: standardOutput, standardError: standardError)
    }
}
