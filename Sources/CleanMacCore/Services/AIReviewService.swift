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
            return """
            - path: \(candidate.url.path)
              sizeBytes: \(candidate.sizeBytes)
              modifiedAt: \(modified)
              category: \(candidate.category.rawValue)
              risk: \(candidate.risk.rawValue)
              reasons: \(reasons)
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

        if let input = standardInput.data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(input)
        }
        try inputPipe.fileHandleForWriting.close()

        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        return CommandResult(
            exitCode: process.terminationStatus,
            standardOutput: String(data: outputData, encoding: .utf8) ?? "",
            standardError: String(data: errorData, encoding: .utf8) ?? ""
        )
    }
}
