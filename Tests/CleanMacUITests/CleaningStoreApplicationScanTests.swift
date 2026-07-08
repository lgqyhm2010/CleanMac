import CleanMacCore
import XCTest
@testable import CleanMac

@MainActor
final class CleaningStoreApplicationScanTests: XCTestCase {
    func testScanApplicationsPopulatesPlansCandidatesAndReport() async throws {
        let sandbox = try makeTemporaryDirectory()
        let apps = sandbox.appending(path: "Applications", directoryHint: .isDirectory)
        try makeAppBundle(apps.appending(path: "Demo.app"), bundleIdentifier: "com.example.demo")

        let store = CleaningStore(
            language: .english,
            aiToolDetector: AIToolDetector(locator: EmptyExecutableLocator())
        )
        store.appRoots = [apps]

        store.scanApplications()
        try await waitForApplicationScan(toFinishIn: store)

        XCTAssertNil(store.errorMessage)
        XCTAssertEqual(store.uninstallPlans.map(\.bundleIdentifier), ["com.example.demo"])
        XCTAssertEqual(store.candidates.map(\.category.rawValue), [CandidateCategory.application.rawValue])
        XCTAssertEqual(store.lastReport?.scannedFileCount, store.candidates.count)
        XCTAssertEqual(store.status, .candidatesFound(store.candidates.count))
    }

    private func waitForApplicationScan(toFinishIn store: CleaningStore) async throws {
        for _ in 0..<100 {
            if !store.isScanningApplications {
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Application scan did not finish")
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

    private func makeAppBundle(_ url: URL, bundleIdentifier: String) throws {
        let contents = url.appending(path: "Contents", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let infoPlist: [String: Any] = [
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundleName": url.deletingPathExtension().lastPathComponent
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: infoPlist, format: .xml, options: 0)
        try data.write(to: contents.appending(path: "Info.plist"))
        try writeFile(contents.appending(path: "MacOS/demo"), contents: "binary")
    }

    private func writeFile(_ url: URL, contents: String) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try contents.data(using: .utf8)?.write(to: url)
    }
}

private struct EmptyExecutableLocator: ExecutableLocating {
    func locate(_ binaryName: String) -> String? {
        nil
    }
}
