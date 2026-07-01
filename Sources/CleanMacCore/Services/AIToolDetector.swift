import Foundation

public struct AIToolProfile: Identifiable, Equatable, Sendable {
    public enum PromptDelivery: Equatable, Sendable {
        case standardInput
        case argument
    }

    public let id: String
    public let displayName: String
    public let binaryName: String
    public let arguments: [String]
    public let promptDelivery: PromptDelivery

    public init(id: String, displayName: String, binaryName: String, arguments: [String], promptDelivery: PromptDelivery) {
        self.id = id
        self.displayName = displayName
        self.binaryName = binaryName
        self.arguments = arguments
        self.promptDelivery = promptDelivery
    }

    /// codex and claude read the prompt from stdin; gemini's `-p` requires the prompt as
    /// the flag's own argument value (confirmed via each CLI's `--help`).
    public static let knownProfiles: [AIToolProfile] = [
        AIToolProfile(id: "codex", displayName: "Codex", binaryName: "codex", arguments: ["exec"], promptDelivery: .standardInput),
        AIToolProfile(id: "claude", displayName: "Claude Code", binaryName: "claude", arguments: ["-p"], promptDelivery: .standardInput),
        AIToolProfile(id: "gemini", displayName: "Gemini CLI", binaryName: "gemini", arguments: ["-p"], promptDelivery: .argument)
    ]
}

public struct DetectedAITool: Identifiable, Equatable, Sendable {
    public var id: String { profile.id }
    public let profile: AIToolProfile
    public let executablePath: String

    public init(profile: AIToolProfile, executablePath: String) {
        self.profile = profile
        self.executablePath = executablePath
    }
}

public protocol ExecutableLocating: Sendable {
    func locate(_ binaryName: String) -> String?
}

/// `Process.executableURL` does not search `$PATH` — a bare binary name fails to launch.
/// This resolves a name to an absolute path the same way a shell would.
public struct PATHExecutableLocator: ExecutableLocating {
    public init() {}

    public func locate(_ binaryName: String) -> String? {
        guard let pathVariable = ProcessInfo.processInfo.environment["PATH"] else { return nil }
        for directory in pathVariable.split(separator: ":") {
            let candidatePath = URL(filePath: String(directory)).appending(path: binaryName).path
            if FileManager.default.isExecutableFile(atPath: candidatePath) {
                return candidatePath
            }
        }
        return nil
    }
}

public struct AIToolDetector {
    private let locator: ExecutableLocating

    public init(locator: ExecutableLocating = PATHExecutableLocator()) {
        self.locator = locator
    }

    public func detectAvailableTools(from profiles: [AIToolProfile] = AIToolProfile.knownProfiles) -> [DetectedAITool] {
        profiles.compactMap { profile in
            guard let executablePath = locator.locate(profile.binaryName) else { return nil }
            return DetectedAITool(profile: profile, executablePath: executablePath)
        }
    }
}
