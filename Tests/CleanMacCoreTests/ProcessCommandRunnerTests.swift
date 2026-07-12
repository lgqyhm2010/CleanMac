import XCTest
@testable import CleanMacCore

final class ProcessCommandRunnerTests: XCTestCase {
    func testDrainsLargeStdoutWithoutDeadlocking() async throws {
        // The child writes ~200KB to stdout — far beyond the ~64KB macOS pipe buffer.
        // The old implementation called waitUntilExit() before reading stdout, so this
        // would deadlock forever.
        let command = AICommand(
            executable: "/bin/sh",
            arguments: ["-c", "yes ABCDEFGH | head -c 200000"]
        )

        let result = try await withTimeout(seconds: 30) {
            try await ProcessCommandRunner().run(command: command, standardInput: "ignored input")
        }

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.standardOutput.utf8.count, 200_000)
    }

    func testKeepsDrainingButBoundsCapturedOutput() async throws {
        let command = AICommand(
            executable: "/bin/sh",
            arguments: ["-c", "yes ABCDEFGH | head -c 200000"],
            maximumCapturedOutputBytes: 1_024
        )

        let result = try await withTimeout(seconds: 30) {
            try await ProcessCommandRunner().run(command: command, standardInput: "")
        }

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.standardOutput.utf8.count, 1_024)
        XCTAssertTrue(result.standardOutputWasTruncated)
    }

    func testReportsNonZeroExitWhenChildIgnoresStdinAndExitsEarly() async throws {
        // The child never reads stdin and exits immediately. Writing a large prompt to a
        // closed pipe must surface as a normal non-zero exit, not crash the app via SIGPIPE.
        let command = AICommand(executable: "/bin/sh", arguments: ["-c", "exit 3"])
        let largeInput = String(repeating: "x", count: 300_000)

        let result = try await withTimeout(seconds: 30) {
            try await ProcessCommandRunner().run(command: command, standardInput: largeInput)
        }

        XCTAssertEqual(result.exitCode, 3)
    }

    func testCapturesStdoutAndStderrSeparately() async throws {
        let command = AICommand(
            executable: "/bin/sh",
            arguments: ["-c", "printf out; printf err 1>&2"]
        )

        let result = try await withTimeout(seconds: 30) {
            try await ProcessCommandRunner().run(command: command, standardInput: "")
        }

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.standardOutput, "out")
        XCTAssertEqual(result.standardError, "err")
    }

    func testAppliesCommandEnvironmentToTheChildProcess() async throws {
        // The spawned CLI must see the environment carried on the AICommand, otherwise the
        // augmented PATH built by AIReviewService never reaches codex/gemini.
        let command = AICommand(
            executable: "/bin/sh",
            arguments: ["-c", "printf %s \"$CLEANMAC_TEST_MARKER\""],
            environment: ["CLEANMAC_TEST_MARKER": "reached-the-child"]
        )

        let result = try await withTimeout(seconds: 30) {
            try await ProcessCommandRunner().run(command: command, standardInput: "")
        }

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.standardOutput, "reached-the-child")
    }

    func testInheritsParentEnvironmentWhenCommandEnvironmentIsNil() async throws {
        // nil environment must leave the child inheriting the parent's, not blank it out.
        setenv("CLEANMAC_PARENT_MARKER", "from-parent", 1)
        defer { unsetenv("CLEANMAC_PARENT_MARKER") }
        let command = AICommand(
            executable: "/bin/sh",
            arguments: ["-c", "printf %s \"$CLEANMAC_PARENT_MARKER\""]
        )

        let result = try await withTimeout(seconds: 30) {
            try await ProcessCommandRunner().run(command: command, standardInput: "")
        }

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.standardOutput, "from-parent")
    }

    func testTerminatesACommandAtItsConfiguredTimeout() async {
        let command = AICommand(
            executable: "/bin/sh",
            arguments: ["-c", "trap '' TERM; exec /bin/sleep 30"],
            timeoutSeconds: 0.1
        )

        let startedAt = Date()
        do {
            _ = try await ProcessCommandRunner().run(command: command, standardInput: "")
            XCTFail("expected timeout")
        } catch {
            XCTAssertTrue(error.localizedDescription.localizedCaseInsensitiveContains("timed out"))
        }
        XCTAssertLessThan(Date().timeIntervalSince(startedAt), 3)
    }

    func testCancellingTheTaskTerminatesTheChildProcess() async {
        let command = AICommand(executable: "/bin/sleep", arguments: ["30"])
        let task = Task {
            try await ProcessCommandRunner().run(command: command, standardInput: "")
        }
        try? await Task.sleep(nanoseconds: 100_000_000)

        let startedAt = Date()
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("expected cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        XCTAssertLessThan(Date().timeIntervalSince(startedAt), 3)
    }

    private struct TimeoutError: Error {}

    private func withTimeout<T: Sendable>(
        seconds: Double,
        _ operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            defer { group.cancelAll() }
            guard let result = try await group.next() else { throw TimeoutError() }
            return result
        }
    }
}
