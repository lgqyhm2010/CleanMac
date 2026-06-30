import XCTest
@testable import CleanMacCore

/// Randomized "monkey" / fuzz tests: hammer the real services with large numbers of
/// random inputs and operation sequences and assert two things — (1) nothing ever
/// crashes or throws unexpectedly, and (2) the safety-critical invariants hold (most
/// importantly: a protected item is NEVER moved to the trash).
///
/// All randomness is seeded so any failure is reproducible — the seed is printed in
/// the failure message. No real files are trashed (a fake `FileTrashing` is used) and
/// every generated file lives in a per-test temp directory that is cleaned up.
final class MonkeyFuzzTests: XCTestCase {
    private let baseSeed: UInt64 = 0xC1EA_11AC_5EED_0001

    // MARK: - Trash safety (the most important invariant)

    func testTrashCleanerNeverTrashesProtectedItemsUnderRandomInput() throws {
        var generator = SeededGenerator(seed: baseSeed ^ 0x7A)

        for iteration in 0..<600 {
            let count = Int.random(in: 0...40, using: &generator)
            var candidates: [CleaningCandidate] = []
            var failURLs: Set<URL> = []

            for index in 0..<count {
                let url = URL(filePath: "/fuzz/iter\(iteration)/item\(index).bin")
                let protection = DeletionProtection.allCases.randomElement(using: &generator)!
                let size = Int64(Int.random(in: 0...10_000, using: &generator))
                candidates.append(
                    CleaningCandidate(
                        url: url,
                        sizeBytes: size,
                        modifiedAt: nil,
                        category: CandidateCategory.allCases.randomElement(using: &generator)!,
                        risk: DeletionRisk.allCases.randomElement(using: &generator)!,
                        reasons: [],
                        isDirectory: Bool.random(using: &generator),
                        protection: protection,
                        ruleMatches: [],
                        userVisibleRules: protection == .blocked ? ["Protected by fuzz"] : []
                    )
                )
                if Bool.random(using: &generator) {
                    failURLs.insert(url)
                }
            }

            let trasher = FuzzTrasher(failURLs: failURLs)
            let result = try TrashCleaner(trasher: trasher).clean(candidates)

            let blocked = candidates.filter { $0.protection == .blocked }
            let movable = candidates.filter { $0.protection != .blocked }
            let trashedSet = Set(trasher.trashed)
            let context = "seed=\(baseSeed) iteration=\(iteration)"

            // The red line: a blocked item must never reach the trasher.
            for item in blocked {
                XCTAssertFalse(trashedSet.contains(item.url), "Protected item was trashed (\(context))")
            }
            // Every blocked item is reported as skipped, and nothing else is.
            XCTAssertEqual(
                Set(result.skipped.map(\.url)),
                Set(blocked.map(\.url)),
                "Skipped set must equal the protected set (\(context))"
            )
            // Accounting adds up: each movable item either trashed or failed.
            XCTAssertEqual(result.cleanedCount, trasher.trashed.count, "cleanedCount mismatch (\(context))")
            XCTAssertEqual(
                result.cleanedCount + result.failures.count,
                movable.count,
                "movable items must be trashed or failed (\(context))"
            )
            XCTAssertEqual(
                result.reclaimedBytes,
                movable.filter { !failURLs.contains($0.url) }.reduce(0) { $0 + $1.sizeBytes },
                "reclaimedBytes must equal the sum of successfully trashed sizes (\(context))"
            )
            XCTAssertGreaterThanOrEqual(result.reclaimedBytes, 0, "reclaimedBytes must be non-negative (\(context))")
        }
    }

    // MARK: - Disk scanning over random file trees

    func testDiskScannerSurvivesRandomFileTrees() throws {
        var generator = SeededGenerator(seed: baseSeed ^ 0x3B)

        for iteration in 0..<40 {
            let root = try makeTemporaryDirectory()
            try populateRandomTree(at: root, depth: 3, generator: &generator)

            let minimum = Int64(Int.random(in: 0...2_048, using: &generator))
            let options = ScanOptions(
                minimumFileSizeBytes: minimum,
                includeHiddenFiles: Bool.random(using: &generator),
                largeFileThresholdBytes: Bool.random(using: &generator)
                    ? Int64(Int.random(in: 1...4_096, using: &generator))
                    : nil
            )

            let report = try DiskScanner().scan(roots: [root], options: options)
            let context = "seed=\(baseSeed) iteration=\(iteration)"

            XCTAssertEqual(
                report.totalBytes,
                report.candidates.reduce(0) { $0 + $1.sizeBytes },
                "totalBytes must equal the sum of candidate sizes (\(context))"
            )
            for candidate in report.candidates {
                XCTAssertGreaterThanOrEqual(candidate.sizeBytes, 0, "Negative size (\(context))")
                XCTAssertGreaterThanOrEqual(
                    candidate.sizeBytes,
                    minimum,
                    "Candidate below the minimum size survived the filter (\(context))"
                )
                // A reported package must never also list one of its own internal files.
                if candidate.isDirectory {
                    let prefix = candidate.url.path + "/"
                    XCTAssertFalse(
                        report.candidates.contains { $0.url.path.hasPrefix(prefix) },
                        "A package and its internals were both reported (\(context))"
                    )
                }
            }
        }
    }

    // MARK: - App uninstaller over random app-like trees

    func testAppUninstallerSurvivesRandomAppTrees() throws {
        var generator = SeededGenerator(seed: baseSeed ^ 0x5D)

        for iteration in 0..<30 {
            let sandbox = try makeTemporaryDirectory()
            let apps = sandbox.appending(path: "Applications", directoryHint: .isDirectory)
            let library = sandbox.appending(path: "Library", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: apps, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: library, withIntermediateDirectories: true)
            try populateRandomAppBundles(in: apps, library: library, generator: &generator)

            let plans = try AppUninstaller().scan(appRoots: [apps], userLibrary: library)
            let context = "seed=\(baseSeed) iteration=\(iteration)"

            for plan in plans {
                XCTAssertFalse(plan.bundleIdentifier.isEmpty, "Plan with empty bundle id (\(context))")
                XCTAssertLessThanOrEqual(
                    plan.movableReclaimableBytes,
                    plan.reclaimableBytes,
                    "Movable bytes cannot exceed total reclaimable bytes (\(context))"
                )
                XCTAssertTrue(
                    plan.movableCandidates.allSatisfy { $0.protection != .blocked },
                    "A blocked candidate leaked into movableCandidates (\(context))"
                )
            }
        }
    }

    // MARK: - Classifier / safety engine over random paths

    func testClassifierAndSafetyEngineAreConsistentUnderRandomPaths() {
        var generator = SeededGenerator(seed: baseSeed ^ 0x9F)
        let segments = [
            "Users", "me", "Library", "Caches", "Logs", "Downloads", "Documents",
            ".Trash", ".Trashes", "trash", "tmp", "TemporaryItems", "Applications",
            "Mobile Documents", "CloudStorage", "Dropbox", "src", ".git", "项目", "a b"
        ]

        for _ in 0..<800 {
            let depth = Int.random(in: 1...7, using: &generator)
            var path = ""
            for _ in 0..<depth {
                path += "/" + segments.randomElement(using: &generator)!
            }
            let ext = ["", ".swift", ".log", ".cache", ".tmp", ".mov", ".bin"].randomElement(using: &generator)!
            let url = URL(filePath: path + "/file" + ext)
            let size = Int64(Int.random(in: 0...2_000_000_000, using: &generator))
            let isDirectory = Bool.random(using: &generator)

            // Must not trap.
            let classification = ScanClassifier().classify(url: url, sizeBytes: size, isDirectory: isDirectory)
            let evaluation = SafetyRuleEngine().evaluate(
                url: url,
                category: classification.category,
                risk: classification.risk,
                reasons: classification.reasons,
                isDirectory: isDirectory
            )

            // The resolved protection must equal the strongest of the matched rules.
            let hasBlocked = evaluation.ruleMatches.contains { $0.protection == .blocked }
            let hasReview = evaluation.ruleMatches.contains { $0.protection == .requiresReview }
            let expected: DeletionProtection = hasBlocked ? .blocked : (hasReview ? .requiresReview : .allowed)
            XCTAssertEqual(evaluation.protection, expected, "Protection is not the strongest matched rule for \(path)")
            XCTAssertEqual(evaluation.userVisibleRules.count, evaluation.ruleMatches.count)
        }
    }

    // MARK: - Helpers

    private func populateRandomTree(at root: URL, depth: Int, generator: inout SeededGenerator) throws {
        let entryCount = Int.random(in: 0...6, using: &generator)
        for index in 0..<entryCount {
            let name = randomName(index: index, generator: &generator)
            if depth > 0, Bool.random(using: &generator) {
                let isPackage = Int.random(in: 0...4, using: &generator) == 0
                let directoryName = isPackage ? name + ".app" : name
                let directory = root.appending(path: directoryName, directoryHint: .isDirectory)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try populateRandomTree(at: directory, depth: depth - 1, generator: &generator)
            } else {
                let ext = ["", ".txt", ".log", ".cache", ".tmp", ".mov", ".dmg"].randomElement(using: &generator)!
                let file = root.appending(path: name + ext)
                let size = Int.random(in: 0...4_096, using: &generator)
                let byte = UInt8(Int.random(in: 0...255, using: &generator))
                try Data(repeating: byte, count: size).write(to: file)
            }
        }
    }

    private func populateRandomAppBundles(in apps: URL, library: URL, generator: inout SeededGenerator) throws {
        let bundleCount = Int.random(in: 0...4, using: &generator)
        for index in 0..<bundleCount {
            let appName = ["Demo", "项目", "My App", "Tool"].randomElement(using: &generator)! + String(index)
            let bundle = apps.appending(path: appName + ".app", directoryHint: .isDirectory)
            let contents = bundle.appending(path: "Contents", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)

            // Sometimes omit the Info.plist / bundle id so the app is correctly ignored.
            if Bool.random(using: &generator) {
                let bundleID = "com.fuzz.app\(index)"
                let plist: [String: Any] = ["CFBundleIdentifier": bundleID, "CFBundleName": appName]
                let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
                try data.write(to: contents.appending(path: "Info.plist"))

                if Bool.random(using: &generator) {
                    try Data(repeating: 7, count: Int.random(in: 0...512, using: &generator))
                        .write(to: library.appending(path: "Application Support/\(bundleID)/data.bin"),
                               options: .atomic, createDirectories: true)
                }
            }
            try Data(repeating: 9, count: Int.random(in: 0...256, using: &generator))
                .write(to: contents.appending(path: "MacOS/binary"), options: .atomic, createDirectories: true)
        }
    }

    private func randomName(index: Int, generator: inout SeededGenerator) -> String {
        let pieces = ["a", "b", "报告", "x y", "data", ".hidden", "caches", "logs", "Downloads", "trash", "tmp"]
        return (pieces.randomElement(using: &generator) ?? "n") + String(index)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }
}

private enum FuzzError: Error { case simulatedTrashFailure }

private final class FuzzTrasher: FileTrashing {
    private(set) var trashed: [URL] = []
    private let failURLs: Set<URL>

    init(failURLs: Set<URL>) {
        self.failURLs = failURLs
    }

    func trashItem(at url: URL) throws {
        if failURLs.contains(url) {
            throw FuzzError.simulatedTrashFailure
        }
        trashed.append(url)
    }
}

/// Deterministic SplitMix64 generator so fuzz failures reproduce from the printed seed.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed != 0 ? seed : 0x9E37_79B9_7F4A_7C15
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

private extension Data {
    /// Convenience writer that creates intermediate directories first.
    func write(to url: URL, options: Data.WritingOptions, createDirectories: Bool) throws {
        if createDirectories {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        }
        try write(to: url, options: options)
    }
}
