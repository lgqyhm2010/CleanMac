import XCTest
@testable import CleanMacCore

final class AppUninstallerTests: XCTestCase {
    func testBuildsPlanForAppBundleWithoutClaimingSupportFiles() throws {
        let sandbox = try makeTemporaryDirectory()
        let apps = sandbox.appending(path: "Applications", directoryHint: .isDirectory)
        let library = sandbox.appending(path: "Library", directoryHint: .isDirectory)
        let app = try makeAppBundle(apps.appending(path: "Demo.app"), bundleIdentifier: "com.example.demo")
        try writeFile(library.appending(path: "Application Support/com.example.demo/data.db"), contents: "support")
        try writeFile(library.appending(path: "Caches/com.example.demo/cache.bin"), contents: "cache")
        try writeFile(library.appending(path: "Preferences/com.example.demo.plist"), contents: "prefs")

        let plans = try AppUninstaller().scan(appRoots: [apps])

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans[0].appName, "Demo")
        XCTAssertEqual(plans[0].bundleIdentifier, "com.example.demo")
        XCTAssertEqual(plans[0].appCandidate.url.path, app.path)
        XCTAssertEqual(plans[0].allCandidates.map(\.url.path), [app.path])
        XCTAssertTrue(plans[0].allCandidates.allSatisfy { $0.protection == .requiresReview })
        XCTAssertTrue(plans[0].allCandidates.allSatisfy { !$0.userVisibleRules.isEmpty })
    }

    func testDoesNotClaimSharedSupportFolderMatchedOnlyByDisplayName() throws {
        let sandbox = try makeTemporaryDirectory()
        let apps = sandbox.appending(path: "Applications", directoryHint: .isDirectory)
        let library = sandbox.appending(path: "Library", directoryHint: .isDirectory)
        // The app's display name ("Vendor") collides with a shared vendor folder used by
        // many apps. Only the reverse-DNS bundle id should be trusted for matching.
        try makeAppBundle(apps.appending(path: "Vendor.app"), bundleIdentifier: "com.vendor.flagship")
        try writeFile(library.appending(path: "Application Support/Vendor/shared-across-apps.db"), contents: "shared")

        let plans = try AppUninstaller().scan(appRoots: [apps])

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans[0].allCandidates.count, 1)
    }

    func testAppBundleSizeIncludesHiddenFiles() throws {
        let sandbox = try makeTemporaryDirectory()
        let apps = sandbox.appending(path: "Applications", directoryHint: .isDirectory)
        let app = try makeAppBundle(apps.appending(path: "Demo.app"), bundleIdentifier: "com.example.demo")
        // Hidden payload inside the bundle (apps store dot-prefixed databases/resources).
        try writeFile(app.appending(path: "Contents/.hidden-db"), contents: "0123456789") // 10 bytes

        let plans = try AppUninstaller().scan(appRoots: [apps])

        let plistSize = try app.appending(path: "Contents/Info.plist")
            .resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        // Info.plist + Contents/MacOS/demo ("binary" = 6 bytes) + hidden 10 bytes.
        let expected = Int64(plistSize) + 6 + 10
        XCTAssertEqual(plans[0].appCandidate.sizeBytes, expected)
    }

    func testIgnoresNonAppDirectoriesAndRequiresBundleIdentifier() throws {
        let sandbox = try makeTemporaryDirectory()
        let apps = sandbox.appending(path: "Applications", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: apps.appending(path: "Folder.app"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: apps.appending(path: "PlainFolder"), withIntermediateDirectories: true)

        let plans = try AppUninstaller().scan(appRoots: [apps])

        XCTAssertTrue(plans.isEmpty)
    }

    func testIgnoresSymlinkedApplicationBundlesInApplicationRoot() throws {
        let sandbox = try makeTemporaryDirectory()
        let apps = sandbox.appending(path: "Applications", directoryHint: .isDirectory)
        let targets = sandbox.appending(path: "SystemApps", directoryHint: .isDirectory)
        let target = try makeAppBundle(targets.appending(path: "Safari.app"), bundleIdentifier: "com.apple.Safari")
        let symlink = apps.appending(path: "Safari.app")
        try FileManager.default.createDirectory(at: apps, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: target)

        let plans = try AppUninstaller().scan(appRoots: [apps])

        XCTAssertTrue(plans.isEmpty)
    }

    func testRejectsBundleIdentifiersContainingPathTraversal() throws {
        let sandbox = try makeTemporaryDirectory()
        let apps = sandbox.appending(path: "Applications", directoryHint: .isDirectory)
        try makeAppBundle(apps.appending(path: "Traversal.app"), bundleIdentifier: "../../Documents")
        try writeFile(sandbox.appending(path: "Documents/private.txt"), contents: "private")

        let plans = try AppUninstaller().scan(appRoots: [apps])

        XCTAssertTrue(plans.isEmpty)
    }

    func testSameBundleIdentifierAtDifferentPathsProducesUniquePlans() throws {
        let sandbox = try makeTemporaryDirectory()
        let systemApps = sandbox.appending(path: "Applications", directoryHint: .isDirectory)
        let userApps = sandbox.appending(path: "User Applications", directoryHint: .isDirectory)
        try makeAppBundle(systemApps.appending(path: "Demo.app"), bundleIdentifier: "com.example.demo")
        try makeAppBundle(userApps.appending(path: "Demo Beta.app"), bundleIdentifier: "com.example.demo")

        let plans = try AppUninstaller().scan(appRoots: [systemApps, userApps])

        XCTAssertEqual(plans.count, 2)
        XCTAssertEqual(Set(plans.map(\.id)).count, 2)
        XCTAssertEqual(Set(plans.map(\.bundleIdentifier)), ["com.example.demo"])
        XCTAssertTrue(plans.allSatisfy { $0.allCandidates.count == 1 })
    }

    func testSearchesNestedAppWhenOuterWrapperHasNoBundleIdentifier() throws {
        let sandbox = try makeTemporaryDirectory()
        let apps = sandbox.appending(path: "Applications", directoryHint: .isDirectory)
        let wrapper = apps.appending(path: "Wrapped.app/Wrapper", directoryHint: .isDirectory)
        try makeAppBundle(wrapper.appending(path: "Wrapped.app"), bundleIdentifier: "com.example.wrapped")

        let plans = try AppUninstaller().scan(appRoots: [apps])

        XCTAssertEqual(plans.map(\.bundleIdentifier), ["com.example.wrapped"])
    }

    func testUnreadableChildDirectoryDoesNotFailEntireApplicationScan() throws {
        let sandbox = try makeTemporaryDirectory()
        let apps = sandbox.appending(path: "Applications", directoryHint: .isDirectory)
        try makeAppBundle(apps.appending(path: "Good.app"), bundleIdentifier: "com.example.good")
        let unreadable = apps.appending(path: "BlockedFolder", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: unreadable, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: unreadable.path)
        addTeardownBlock {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: unreadable.path)
        }

        let plans = try AppUninstaller().scan(appRoots: [apps])

        XCTAssertEqual(plans.map(\.bundleIdentifier), ["com.example.good"])
    }

    func testPlanContainsOnlyTheApplicationBundle() throws {
        let app = candidate(path: "/Applications/Demo.app", category: .application, protection: .requiresReview)

        let plan = AppUninstallPlan(
            appName: "Demo",
            bundleIdentifier: "com.example.demo",
            appCandidate: app
        )

        XCTAssertEqual(plan.allCandidates.map(\.url.path), [app.url.path])
        XCTAssertEqual(plan.movableCandidates.map(\.url.path), [app.url.path])
        XCTAssertEqual(plan.reclaimableBytes, app.sizeBytes)
        XCTAssertEqual(plan.movableReclaimableBytes, app.sizeBytes)
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
