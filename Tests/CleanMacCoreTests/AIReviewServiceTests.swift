import XCTest
@testable import CleanMacCore

final class AIReviewServiceTests: XCTestCase {
    func testPromptIncludesCandidateContextAndUserQuestion() {
        let service = AIReviewService(
            command: AICommand(executable: "/usr/bin/ai", arguments: ["--quiet"]),
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

    func testReviewRunsConfiguredCommandWithGeneratedPrompt() async throws {
        let runner = RecordingCommandRunner()
        let command = AICommand(executable: "/usr/bin/ai", arguments: ["review"])
        let service = AIReviewService(command: command, runner: runner)
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
        XCTAssertEqual(runner.commands, [command])
        XCTAssertEqual(runner.standardInputs.count, 1)
        XCTAssertTrue(runner.standardInputs[0].contains("/tmp/cache.bin"))
    }

    func testReviewThrowsErrorDescribingWhyTheCommandFailed() async {
        let runner = FailingCommandRunner(
            exitCode: 1,
            standardError: "Error loading config.toml: unknown variant `default`, expected `fast` or `flex` in `service_tier`"
        )
        let service = AIReviewService(
            command: AICommand(executable: "/usr/bin/env", arguments: ["codex", "exec"]),
            runner: runner
        )
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
