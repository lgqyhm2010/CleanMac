import XCTest
@testable import CleanMacCore

final class AppUninstallerTests: XCTestCase {
    func testBuildsPlanForAppBundleAndKnownSupportFiles() throws {
        let sandbox = try makeTemporaryDirectory()
        let apps = sandbox.appending(path: "Applications", directoryHint: .isDirectory)
        let library = sandbox.appending(path: "Library", directoryHint: .isDirectory)
        let app = try makeAppBundle(apps.appending(path: "Demo.app"), bundleIdentifier: "com.example.demo")
        try writeFile(library.appending(path: "Application Support/com.example.demo/data.db"), contents: "support")
        try writeFile(library.appending(path: "Caches/com.example.demo/cache.bin"), contents: "cache")
        try writeFile(library.appending(path: "Preferences/com.example.demo.plist"), contents: "prefs")

        let plans = try AppUninstaller().scan(appRoots: [apps], userLibrary: library)

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans[0].appName, "Demo")
        XCTAssertEqual(plans[0].bundleIdentifier, "com.example.demo")
        XCTAssertEqual(plans[0].appCandidate.url.path, app.path)
        XCTAssertEqual(plans[0].supportCandidates.count, 3)
        XCTAssertEqual(plans[0].supportCandidates.map(\.url.lastPathComponent).sorted(), [
            "cache.bin",
            "com.example.demo.plist",
            "data.db"
        ])
        XCTAssertTrue(plans[0].allCandidates.allSatisfy { $0.protection == .requiresReview })
        XCTAssertTrue(plans[0].allCandidates.allSatisfy { !$0.userVisibleRules.isEmpty })
    }

    func testIgnoresNonAppDirectoriesAndRequiresBundleIdentifier() throws {
        let sandbox = try makeTemporaryDirectory()
        let apps = sandbox.appending(path: "Applications", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: apps.appending(path: "Folder.app"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: apps.appending(path: "PlainFolder"), withIntermediateDirectories: true)

        let plans = try AppUninstaller().scan(appRoots: [apps], userLibrary: sandbox.appending(path: "Library"))

        XCTAssertTrue(plans.isEmpty)
    }

    func testPlanSelectsOnlyMovableUninstallCandidates() throws {
        let app = candidate(path: "/Applications/Demo.app", category: .application, protection: .requiresReview)
        let support = candidate(path: "/Users/me/Library/Caches/com.example.demo", category: .applicationSupport, protection: .requiresReview)
        let blocked = candidate(path: "/System/Library/com.example.demo", category: .applicationSupport, protection: .blocked)

        let plan = AppUninstallPlan(
            appName: "Demo",
            bundleIdentifier: "com.example.demo",
            appCandidate: app,
            supportCandidates: [support, blocked]
        )

        XCTAssertEqual(plan.allCandidates.map(\.url.path), [app.url.path, support.url.path, blocked.url.path])
        XCTAssertEqual(plan.movableCandidates.map(\.url.path), [app.url.path, support.url.path])
        XCTAssertEqual(plan.reclaimableBytes, app.sizeBytes + support.sizeBytes + blocked.sizeBytes)
        XCTAssertEqual(plan.movableReclaimableBytes, app.sizeBytes + support.sizeBytes)
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
    private func makeAppBundle(_ url: URL, bundleIdentifier: String) throws -> URL {
        let contents = url.appending(path: "Contents", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let infoPlist: [String: Any] = [
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundleName": url.deletingPathExtension().lastPathComponent
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: infoPlist, format: .xml, options: 0)
        try data.write(to: contents.appending(path: "Info.plist"))
        try writeFile(contents.appending(path: "MacOS/demo"), contents: "binary")
        return url
    }

    private func writeFile(_ url: URL, contents: String) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try contents.data(using: .utf8)?.write(to: url)
    }

    private func candidate(
        path: String,
        category: CandidateCategory,
        protection: DeletionProtection
    ) -> CleaningCandidate {
        CleaningCandidate(
            url: URL(filePath: path),
            sizeBytes: 10,
            modifiedAt: nil,
            category: category,
            risk: .reviewRecommended,
            reasons: [],
            isDirectory: true,
            protection: protection,
            ruleMatches: [],
            userVisibleRules: []
        )
    }
}
