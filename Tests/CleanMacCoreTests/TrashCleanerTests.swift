import XCTest
@testable import CleanMacCore

final class TrashCleanerTests: XCTestCase {
    func testCleanerMovesCandidatesToTrashAndReportsReclaimedBytes() throws {
        let trasher = RecordingFileTrasher()
        let candidates = [
            candidate(path: "/tmp/a.cache", size: 10),
            candidate(path: "/tmp/b.log", size: 20)
        ]
        let cleaner = TrashCleaner(
            trasher: trasher,
            snapshotReader: StaticSnapshotReader(candidates: candidates)
        )
        let result = try cleaner.clean(candidates)

        XCTAssertEqual(trasher.urls, candidates.map(\.url))
        XCTAssertEqual(result.cleanedCount, 2)
        XCTAssertEqual(result.reclaimedBytes, 30)
        XCTAssertTrue(result.failures.isEmpty)
        XCTAssertTrue(result.skipped.isEmpty)
    }

    func testCleanerDoesNotTrashBlockedCandidates() throws {
        let trasher = RecordingFileTrasher()
        let safe = candidate(path: "/tmp/a.cache", size: 10, protection: .allowed)
        let blocked = candidate(path: "/System/Library/do-not-touch", size: 20, protection: .blocked)
        let cleaner = TrashCleaner(
            trasher: trasher,
            snapshotReader: StaticSnapshotReader(candidates: [safe, blocked])
        )

        let result = try cleaner.clean([safe, blocked])

        XCTAssertEqual(trasher.urls, [safe.url])
        XCTAssertEqual(result.cleanedCount, 1)
        XCTAssertEqual(result.reclaimedBytes, 10)
        XCTAssertTrue(result.failures.isEmpty)
        XCTAssertEqual(result.skipped.count, 1)
        XCTAssertEqual(result.skipped.first?.url, blocked.url)
        XCTAssertTrue(result.skipped.first?.message.localizedCaseInsensitiveContains("protected") == true)
    }

    func testCleanerSkipsFileWhoseIdentityChangedAfterScan() throws {
        let url = try makeTemporaryFile(contents: "same")
        let scanned = candidate(
            url: url,
            size: 4,
            scanSnapshot: try XCTUnwrap(FileSnapshot.capture(at: url))
        )
        try FileManager.default.removeItem(at: url)
        try Data("same".utf8).write(to: url)

        let trasher = RecordingFileTrasher()
        let result = try TrashCleaner(trasher: trasher).clean([scanned])

        XCTAssertTrue(trasher.urls.isEmpty)
        XCTAssertEqual(result.cleanedCount, 0)
        XCTAssertEqual(result.skipped.map(\.url), [url])
        XCTAssertTrue(result.skipped[0].message.localizedCaseInsensitiveContains("changed"))
    }

    func testCleanerSkipsFileWhoseMetadataChangedAfterScan() throws {
        let url = try makeTemporaryFile(contents: "same")
        let scanned = candidate(
            url: url,
            size: 4,
            scanSnapshot: try XCTUnwrap(FileSnapshot.capture(at: url))
        )
        try Data("different".utf8).write(to: url)

        let trasher = RecordingFileTrasher()
        let result = try TrashCleaner(trasher: trasher).clean([scanned])

        XCTAssertTrue(trasher.urls.isEmpty)
        XCTAssertEqual(result.skipped.first?.reason, .changedSinceScan)
    }

    func testCleanerFailsClosedWhenScanSnapshotIsUnavailable() throws {
        let target = CleaningCandidate(
            url: URL(filePath: "/tmp/no-snapshot.cache"),
            sizeBytes: 4,
            modifiedAt: nil,
            category: .cache,
            risk: .usuallySafe,
            reasons: [],
            isDirectory: false,
            protection: .allowed,
            scanSnapshot: nil
        )
        let trasher = RecordingFileTrasher()

        let result = try TrashCleaner(trasher: trasher).clean([target])

        XCTAssertTrue(trasher.urls.isEmpty)
        XCTAssertEqual(result.skipped.first?.reason, .snapshotUnavailable)
    }

    func testCleanerRehashesDuplicateTargetBeforeMovingIt() throws {
        let url = try makeTemporaryFile(contents: "diff")
        let target = candidate(
            url: url,
            size: 4,
            scanSnapshot: try XCTUnwrap(FileSnapshot.capture(at: url))
        )
        let request = CleanupRequest(candidate: target, expectedContentHash: String(repeating: "0", count: 64))
        let trasher = RecordingFileTrasher()

        let result = try TrashCleaner(trasher: trasher).clean([request])

        XCTAssertTrue(trasher.urls.isEmpty)
        XCTAssertEqual(result.cleanedCount, 0)
        XCTAssertEqual(result.skipped.map(\.url), [url])
        XCTAssertTrue(result.skipped[0].message.localizedCaseInsensitiveContains("content"))
    }

    private func makeTemporaryFile(contents: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "candidate.bin")
        try Data(contents.utf8).write(to: url)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return url
    }

    private func candidate(
        path: String,
        size: Int64,
        protection: DeletionProtection = .allowed
    ) -> CleaningCandidate {
        candidate(url: URL(filePath: path), size: size, protection: protection)
    }

    private func candidate(
        url: URL,
        size: Int64,
        protection: DeletionProtection = .allowed,
        scanSnapshot: FileSnapshot? = nil
    ) -> CleaningCandidate {
        let snapshot = scanSnapshot ?? FileSnapshot(
            identity: FileSystemIdentity(
                deviceID: 1,
                fileID: UInt64(bitPattern: Int64(url.path.hashValue))
            ),
            linkCount: 1,
            kind: .regularFile,
            byteCount: size,
            modifiedAtNanoseconds: 1,
            statusChangedAtNanoseconds: 1
        )
        return CleaningCandidate(
            url: url,
            sizeBytes: size,
            modifiedAt: nil,
            category: .cache,
            risk: .usuallySafe,
            reasons: [],
            isDirectory: false,
            protection: protection,
            ruleMatches: [],
            userVisibleRules: [],
            scanSnapshot: snapshot
        )
    }
}

private final class RecordingFileTrasher: FileTrashing {
    private(set) var urls: [URL] = []

    func trashItem(at url: URL) throws {
        urls.append(url)
    }
}

private struct StaticSnapshotReader: FileSnapshotReading {
    private let snapshots: [URL: FileSnapshot]

    init(candidates: [CleaningCandidate]) {
        snapshots = Dictionary(uniqueKeysWithValues: candidates.compactMap { candidate in
            candidate.scanSnapshot.map { (candidate.url, $0) }
        })
    }

    func snapshot(at url: URL) -> FileSnapshot? {
        snapshots[url]
    }
}
