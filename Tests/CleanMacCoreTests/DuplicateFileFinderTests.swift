import XCTest
@testable import CleanMacCore

final class DuplicateFileFinderTests: XCTestCase {
    func testFindsDuplicateGroupsByContentHashNotNameOrSizeOnly() throws {
        let root = try makeTemporaryDirectory()
        let first = try writeFile(root.appending(path: "a/report.txt"), contents: "same")
        let second = try writeFile(root.appending(path: "b/copy.txt"), contents: "same")
        let sameSizeDifferentContent = try writeFile(root.appending(path: "c/not-a-copy.txt"), contents: "diff")

        let groups = try DuplicateFileFinder().findDuplicates(in: [
            candidate(url: first, size: 4),
            candidate(url: second, size: 4),
            candidate(url: sameSizeDifferentContent, size: 4)
        ])

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].candidates.map(\.url.lastPathComponent).sorted(), ["copy.txt", "report.txt"])
        XCTAssertEqual(groups[0].reclaimableBytes, 4)
    }

    func testSkipsUnreadableFilesInsteadOfFailingEntireScan() throws {
        let root = try makeTemporaryDirectory()
        let first = try writeFile(root.appending(path: "a/report.txt"), contents: "same")
        let second = try writeFile(root.appending(path: "b/copy.txt"), contents: "same")
        // A candidate that vanished between scan and hashing (or is permission-denied):
        // the file is never created on disk, so reading it would throw.
        let missing = root.appending(path: "c/ghost.txt")

        let groups = try DuplicateFileFinder().findDuplicates(in: [
            candidate(url: first, size: 4),
            candidate(url: second, size: 4),
            candidate(url: missing, size: 4)
        ])

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].candidates.map(\.url.lastPathComponent).sorted(), ["copy.txt", "report.txt"])
    }

    func testIgnoresDirectoriesEmptyFilesAndSingleFiles() throws {
        let root = try makeTemporaryDirectory()
        let file = try writeFile(root.appending(path: "lonely.txt"), contents: "only")
        let emptyOne = try writeFile(root.appending(path: "empty-a"), contents: "")
        let emptyTwo = try writeFile(root.appending(path: "empty-b"), contents: "")

        let groups = try DuplicateFileFinder().findDuplicates(in: [
            candidate(url: file, size: 4),
            candidate(url: emptyOne, size: 0),
            candidate(url: emptyTwo, size: 0),
            candidate(url: root.appending(path: "folder"), size: 4, isDirectory: true)
        ])

        XCTAssertTrue(groups.isEmpty)
    }

    func testPreferredOriginalKeepsNewestFileAndSelectsOnlyMovableCopies() {
        let old = candidate(
            path: "/tmp/old.txt",
            size: 10,
            modifiedAt: Date(timeIntervalSince1970: 1),
            protection: .allowed
        )
        let newest = candidate(
            path: "/tmp/new.txt",
            size: 10,
            modifiedAt: Date(timeIntervalSince1970: 2),
            protection: .allowed
        )
        let blocked = candidate(
            path: "/System/copy.txt",
            size: 10,
            modifiedAt: Date(timeIntervalSince1970: 0),
            protection: .blocked
        )
        let group = DuplicateFileGroup(contentHash: "hash", sizeBytes: 10, candidates: [old, newest, blocked])

        XCTAssertEqual(group.preferredOriginal?.url.path, newest.url.path)
        XCTAssertEqual(group.movableDuplicateCandidates.map(\.url.path), [old.url.path])
        XCTAssertEqual(group.reclaimableBytes, 20)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }
        return url
    }

    @discardableResult
    private func writeFile(_ url: URL, contents: String) throws -> URL {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try contents.data(using: .utf8)?.write(to: url)
        return url
    }

    private func candidate(
        path: String,
        size: Int64,
        modifiedAt: Date? = nil,
        protection: DeletionProtection = .allowed,
        isDirectory: Bool = false
    ) -> CleaningCandidate {
        candidate(
            url: URL(filePath: path),
            size: size,
            modifiedAt: modifiedAt,
            protection: protection,
            isDirectory: isDirectory
        )
    }

    private func candidate(
        url: URL,
        size: Int64,
        modifiedAt: Date? = nil,
        protection: DeletionProtection = .allowed,
        isDirectory: Bool = false
    ) -> CleaningCandidate {
        CleaningCandidate(
            url: url,
            sizeBytes: size,
            modifiedAt: modifiedAt,
            category: .other,
            risk: .reviewRecommended,
            reasons: [],
            isDirectory: isDirectory,
            protection: protection,
            ruleMatches: [],
            userVisibleRules: []
        )
    }
}
