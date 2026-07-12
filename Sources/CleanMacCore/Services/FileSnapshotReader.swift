import Darwin
import Foundation

public protocol FileSnapshotReading: Sendable {
    func snapshot(at url: URL) -> FileSnapshot?
}

public struct SystemFileSnapshotReader: FileSnapshotReading, Sendable {
    public init() {}

    public func snapshot(at url: URL) -> FileSnapshot? {
        var metadata = stat()
        let result = url.withUnsafeFileSystemRepresentation { path in
            guard let path else { return Int32(-1) }
            return Darwin.lstat(path, &metadata)
        }
        guard result == 0 else { return nil }

        return FileSnapshot(
            identity: FileSystemIdentity(
                deviceID: UInt64(truncatingIfNeeded: metadata.st_dev),
                fileID: UInt64(truncatingIfNeeded: metadata.st_ino)
            ),
            linkCount: UInt64(truncatingIfNeeded: metadata.st_nlink),
            kind: kind(for: metadata.st_mode),
            byteCount: Int64(metadata.st_size),
            modifiedAtNanoseconds: nanoseconds(metadata.st_mtimespec),
            statusChangedAtNanoseconds: nanoseconds(metadata.st_ctimespec)
        )
    }

    private func kind(for mode: mode_t) -> FileSnapshotKind {
        switch mode & S_IFMT {
        case S_IFREG: .regularFile
        case S_IFDIR: .directory
        case S_IFLNK: .symbolicLink
        default: .other
        }
    }

    private func nanoseconds(_ value: timespec) -> Int64 {
        Int64(value.tv_sec) * 1_000_000_000 + Int64(value.tv_nsec)
    }
}

public extension FileSnapshot {
    static func capture(at url: URL) -> FileSnapshot? {
        SystemFileSnapshotReader().snapshot(at: url)
    }
}
