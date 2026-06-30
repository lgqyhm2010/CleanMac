import XCTest
@testable import CleanMacCore

final class DiskScannerTests: XCTestCase {
    func testScanFindsFilesAboveMinimumSizeAndBuildsSummary() throws {
        let root = try makeTemporaryDirectory()
        try writeFile(root.appending(path: "Library/Caches/demo/cache.bin"), byteCount: 12)
        try writeFile(root.appending(path: "Library/Logs/app.log"), byteCount: 7)
        try writeFile(root.appending(path: "tiny.txt"), byteCount: 2)
        try writeFile(root.appending(path: ".hidden-cache"), byteCount: 99)

        let scanner = DiskScanner(classifier: ScanClassifier(largeFileThresholdBytes: 100))
        let report = try scanner.scan(
            roots: [root],
            options: ScanOptions(minimumFileSizeBytes: 5, includeHiddenFiles: false)
        )

        XCTAssertEqual(report.candidates.map(\.url.lastPathComponent).sorted(), ["app.log", "cache.bin"])
        XCTAssertEqual(report.totalBytes, 19)
        XCTAssertEqual(report.scannedFileCount, 4)
        XCTAssertEqual(report.skippedFileCount, 2)
        XCTAssertEqual(report.candidates.first { $0.url.lastPathComponent == "cache.bin" }?.category, .cache)
        XCTAssertEqual(report.candidates.first { $0.url.lastPathComponent == "app.log" }?.category, .logs)
    }

    func testScannerUsesInjectedClassifierWhenOptionsDoNotOverrideLargeFileThreshold() throws {
        let root = try makeTemporaryDirectory()
        try writeFile(root.appending(path: "movie.mov"), byteCount: 101)

        let scanner = DiskScanner(classifier: ScanClassifier(largeFileThresholdBytes: 100))
        let report = try scanner.scan(
            roots: [root],
            options: ScanOptions(minimumFileSizeBytes: 1, includeHiddenFiles: false)
        )

        XCTAssertEqual(report.candidates.first?.category, .largeFile)
    }

    func testScanReportsDuplicateGroupsAndReclaimableBytes() throws {
        let root = try makeTemporaryDirectory()
        try writeFile(root.appending(path: "one.txt"), contents: "same")
        try writeFile(root.appending(path: "copy/one-copy.txt"), contents: "same")
        try writeFile(root.appending(path: "different.txt"), contents: "diff")

        let report = try DiskScanner(classifier: ScanClassifier(largeFileThresholdBytes: 100))
            .scan(roots: [root], options: ScanOptions(minimumFileSizeBytes: 1, includeHiddenFiles: false))

        XCTAssertEqual(report.duplicateGroups.count, 1)
        XCTAssertEqual(report.duplicateGroups.first?.candidates.count, 2)
        XCTAssertEqual(report.duplicateReclaimableBytes, 4)
    }

    func testReportsFileSystemPackagesAsSingleSizedCandidates() throws {
        let root = try makeTemporaryDirectory()
        // A .app is a file-system package: it must be reported as one sized item, not
        // skipped entirely (old behavior) and not exploded into its inner files.
        try writeFile(root.appending(path: "Big.app/Contents/MacOS/bin"), byteCount: 50)
        try writeFile(root.appending(path: "Big.app/Contents/Resources/data.bin"), byteCount: 70)

        let report = try DiskScanner(classifier: ScanClassifier(largeFileThresholdBytes: 1_000))
            .scan(roots: [root], options: ScanOptions(minimumFileSizeBytes: 1, includeHiddenFiles: false))

        let package = report.candidates.first { $0.url.lastPathComponent == "Big.app" }
        XCTAssertNotNil(package, "Package was skipped instead of reported")
        XCTAssertEqual(package?.isDirectory, true)
        XCTAssertEqual(package?.sizeBytes, 120)
        XCTAssertFalse(report.candidates.contains { $0.url.lastPathComponent == "bin" })
        XCTAssertFalse(report.candidates.contains { $0.url.lastPathComponent == "data.bin" })
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

    private func writeFile(_ url: URL, byteCount: Int) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = Data(repeating: 65, count: byteCount)
        try data.write(to: url)
    }

    private func writeFile(_ url: URL, contents: String) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try contents.data(using: .utf8)?.write(to: url)
    }
}
