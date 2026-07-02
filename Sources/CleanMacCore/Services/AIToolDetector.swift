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

/// The directories CleanMac searches for AI CLIs, and the `PATH` it hands the spawned
/// process. A macOS app launched from Finder/Dock inherits only launchd's minimal PATH
/// (`/usr/bin:/bin:/usr/sbin:/sbin`), which omits Homebrew, `~/.local/bin`, and the npm
/// global dir where codex/claude/gemini — and the `node` their shebangs need — actually
/// live. Unioning the inherited PATH with the well-known install locations makes both
/// detection and launch work regardless of how the app was started.
enum ExecutableSearchPath {
    /// Standard macOS CLI install locations, in priority order. Absolute paths only.
    static func wellKnownDirectories(homeDirectory: String) -> [String] {
        [
            "/opt/homebrew/bin",        // Apple Silicon Homebrew (codex, gemini, node)
            "/opt/homebrew/sbin",
            "/usr/local/bin",           // Intel Homebrew / manual installs
            "/usr/local/sbin",
            "\(homeDirectory)/.local/bin",      // pipx, uv, claude
            "\(homeDirectory)/.npm-global/bin", // custom npm prefix
            "\(homeDirectory)/bin",
            "\(homeDirectory)/.asdf/shims",     // asdf version manager
            "\(homeDirectory)/.volta/bin",      // volta
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ]
    }

    /// The inherited `$PATH` followed by the well-known dirs, de-duplicated and with any
    /// empty or relative entry dropped (a relative entry would resolve against the process
    /// working directory — `/` for a GUI app — which is never what we want).
    static func directories(environmentPATH: String, homeDirectory: String) -> [String] {
        let inherited = environmentPATH.split(separator: ":").map(String.init)
        var seen = Set<String>()
        return (inherited + wellKnownDirectories(homeDirectory: homeDirectory)).filter { directory in
            directory.hasPrefix("/") && seen.insert(directory).inserted
        }
    }

    static func directories() -> [String] {
        directories(
            environmentPATH: ProcessInfo.processInfo.environment["PATH"] ?? "",
            homeDirectory: FileManager.default.homeDirectoryForCurrentUser.path
        )
    }

    /// The augmented `PATH` string handed to a spawned CLI so its own `env node` shebang
    /// and any child processes resolve against the same locations used for detection.
    static func combinedPATH() -> String {
        directories().joined(separator: ":")
    }
}

/// `Process.executableURL` does not search `$PATH` — a bare binary name fails to launch.
/// This resolves a name to an absolute path the same way a shell would, searching the
/// augmented `ExecutableSearchPath` so tools are found even under a minimal GUI PATH.
public struct PATHExecutableLocator: ExecutableLocating {
    private let searchDirectories: [String]
    private let isLaunchable: @Sendable (String) -> Bool

    public init() {
        self.init(searchDirectories: ExecutableSearchPath.directories())
    }

    init(searchDirectories: [String]) {
        self.init(searchDirectories: searchDirectories, isLaunchable: PATHExecutableLocator.isLaunchableFile)
    }

    init(searchDirectories: [String], isLaunchable: @escaping @Sendable (String) -> Bool) {
        self.searchDirectories = searchDirectories
        self.isLaunchable = isLaunchable
    }

    public func locate(_ binaryName: String) -> String? {
        for directory in searchDirectories {
            let candidatePath = URL(filePath: directory).appending(path: binaryName).path
            if isLaunchable(candidatePath) {
                return candidatePath
            }
        }
        return nil
    }

    /// `FileManager.isExecutableFile` also returns `true` for directories, so a directory
    /// named like a CLI would be reported as a launchable tool (and then fail to launch).
    /// Require a regular, non-directory, executable file.
    private static let isLaunchableFile: @Sendable (String) -> Bool = { path in
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && !isDirectory.boolValue && FileManager.default.isExecutableFile(atPath: path)
    }
}

public struct AIToolDetector: Sendable {
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
