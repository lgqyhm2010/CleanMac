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
            standardError: "Error loading config.toml: unknown variant `default`, expected `fast` or `flex` in `service_tier`"
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

    init(exitCode: Int32, standardError: String) {
        self.exitCode = exitCode
        self.standardError = standardError
    }

    func run(command: AICommand, standardInput: String) async throws -> CommandResult {
        CommandResult(exitCode: exitCode, standardOutput: "", standardError: standardError)
    }
}
