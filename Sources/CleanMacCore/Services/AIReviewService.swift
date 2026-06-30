import Foundation

public protocol CommandRunning {
    func run(command: AICommand, standardInput: String) async throws -> CommandResult
}

public enum AIReviewError: Error, Equatable {
    case commandFailed(exitCode: Int32, standardError: String)
}

public final class AIReviewService {
    private let command: AICommand
    private let runner: CommandRunning

    public init(command: AICommand, runner: CommandRunning = ProcessCommandRunner()) {
        self.command = command
        self.runner = runner
    }

    public func makePrompt(candidates: [CleaningCandidate], userQuestion: String) -> String {
        let rows = candidates.prefix(80).map { candidate in
            let modified = candidate.modifiedAt.map { ISO8601DateFormatter().string(from: $0) } ?? "unknown"
            let reasons = candidate.reasons.joined(separator: "; ")
            let rules = candidate.userVisibleRules.joined(separator: "; ")
            return """
            - path: \(candidate.url.path)
              sizeBytes: \(candidate.sizeBytes)
              modifiedAt: \(modified)
              category: \(candidate.category.rawValue)
              risk: \(candidate.risk.rawValue)
              reasons: \(reasons)
              protection: \(candidate.protection.rawValue)
              rules: \(rules)
            """
        }
        .joined(separator: "\n")

        return """
        You are helping review macOS disk-cleanup candidates before deletion.
        The user will move selected files to Trash, not permanently delete them.
        Answer in concise JSON with keys: summary, safe_to_delete, risky, needs_user_review.
        Prefer caution for personal documents, source code, app data, and unknown paths.

        User question:
        \(userQuestion)

        Candidates:
        \(rows)
        """
    }

    public func review(candidates: [CleaningCandidate], userQuestion: String) async throws -> AIReview {
        let prompt = makePrompt(candidates: candidates, userQuestion: userQuestion)
        let result = try await runner.run(command: command, standardInput: prompt)
        guard result.exitCode == 0 else {
            throw AIReviewError.commandFailed(
                exitCode: result.exitCode,
                standardError: result.standardError
            )
        }
        return AIReview(output: result.standardOutput, reviewedAt: Date())
    }
}

public struct ProcessCommandRunner: CommandRunning {
    public init() {}

    public func run(command: AICommand, standardInput: String) async throws -> CommandResult {
        // A broken pipe (child exits before reading all of stdin) must surface as a
        // non-zero exit code, not a SIGPIPE that kills the whole app.
        _ = Self.sigpipeIgnored

        let payload = UnsafeTransfer((command, standardInput))
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let (command, standardInput) = payload.value
                    let result = try Self.runSynchronously(command: command, standardInput: standardInput)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func runSynchronously(command: AICommand, standardInput: String) throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(filePath: command.executable)
        process.arguments = command.arguments

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()

        // Drain stdout and stderr concurrently *while* the child runs. macOS pipe
        // buffers are small (~64KB); if we waited for the process to exit before
        // reading, a chatty command would block on a full pipe and never exit,
        // deadlocking against waitUntilExit().
        let outputSink = UnsafeTransfer(outputPipe.fileHandleForReading)
        let errorSink = UnsafeTransfer(errorPipe.fileHandleForReading)
        let outputBox = DataBox()
        let errorBox = DataBox()
        let drainGroup = DispatchGroup()

        drainGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            outputBox.value = outputSink.value.readDataToEndOfFile()
            drainGroup.leave()
        }
        drainGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            errorBox.value = errorSink.value.readDataToEndOfFile()
            drainGroup.leave()
        }

        // Writing can fail with a broken pipe if the child already exited; that is
        // not fatal — the child's exit code is what the caller cares about.
        let writeHandle = inputPipe.fileHandleForWriting
        if let input = standardInput.data(using: .utf8) {
            try? writeHandle.write(contentsOf: input)
        }
        try? writeHandle.close()

        drainGroup.wait()
        process.waitUntilExit()

        return CommandResult(
            exitCode: process.terminationStatus,
            standardOutput: String(data: outputBox.value, encoding: .utf8) ?? "",
            standardError: String(data: errorBox.value, encoding: .utf8) ?? ""
        )
    }

    private static let sigpipeIgnored: Void = {
        signal(SIGPIPE, SIG_IGN)
    }()
}

/// Carries a non-`Sendable` value across a concurrency boundary when the caller
/// guarantees it is only touched on one thread at a time.
private struct UnsafeTransfer<Value>: @unchecked Sendable {
    let value: Value
    init(_ value: Value) { self.value = value }
}

/// A reference box used to hand a drained pipe's data back from a background
/// queue; written once before `DispatchGroup.wait()` establishes happens-before.
private final class DataBox: @unchecked Sendable {
    var value = Data()
}
