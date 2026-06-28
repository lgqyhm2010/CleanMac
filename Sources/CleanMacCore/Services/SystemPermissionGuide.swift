import Foundation

public enum SystemPermissionKind: String, Codable, Hashable, Identifiable, Sendable {
    case fullDiskAccess

    public var id: String { rawValue }
}

public enum SystemPermissionStatus: String, Codable, Hashable, Identifiable, Sendable {
    case granted
    case needsAttention
    case unavailable

    public var id: String { rawValue }
}

public struct PermissionProbe: Sendable {
    public let protectedLocations: [URL]
    private let canReadDirectoryHandler: @Sendable (URL) -> Bool

    public init(
        protectedLocations: [URL] = Self.defaultProtectedLocations(),
        canReadDirectory: @escaping @Sendable (URL) -> Bool = Self.defaultCanReadDirectory
    ) {
        self.protectedLocations = protectedLocations
        self.canReadDirectoryHandler = canReadDirectory
    }

    public func canReadAnyProtectedLocation() -> Bool {
        protectedLocations.contains { canReadDirectoryHandler($0) }
    }

    public static func defaultProtectedLocations() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appending(path: "Library/Mail", directoryHint: .isDirectory),
            home.appending(path: "Library/Messages", directoryHint: .isDirectory),
            home.appending(path: "Library/Safari", directoryHint: .isDirectory)
        ]
    }

    public static func defaultCanReadDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return false
        }
        return FileManager.default.isReadableFile(atPath: url.path)
    }
}

public struct SystemPermissionGuide: Equatable, Sendable {
    public let kind: SystemPermissionKind
    public let status: SystemPermissionStatus
    public let title: String
    public let explanation: String
    public let instructions: [String]
    public let settingsURL: URL?

    public init(
        kind: SystemPermissionKind,
        status: SystemPermissionStatus,
        title: String,
        explanation: String,
        instructions: [String],
        settingsURL: URL?
    ) {
        self.kind = kind
        self.status = status
        self.title = title
        self.explanation = explanation
        self.instructions = instructions
        self.settingsURL = settingsURL
    }

    public static func fullDiskAccess(probe: PermissionProbe = PermissionProbe()) -> SystemPermissionGuide {
        SystemPermissionGuide(
            kind: .fullDiskAccess,
            status: fullDiskAccessStatus(probe: probe),
            title: "Full Disk Access",
            explanation: "Full Disk Access lets CleanMac scan protected folders such as Mail, Messages, and Safari data. Without it, scans can miss files macOS hides from normal apps.",
            instructions: [
                "Open System Settings > Privacy & Security > Full Disk Access.",
                "Enable Full Disk Access for CleanMac.",
                "Quit and reopen CleanMac, then scan again."
            ],
            settingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
        )
    }

    private static func fullDiskAccessStatus(probe: PermissionProbe) -> SystemPermissionStatus {
        guard !probe.protectedLocations.isEmpty else {
            return .unavailable
        }
        return probe.canReadAnyProtectedLocation() ? .granted : .needsAttention
    }
}
