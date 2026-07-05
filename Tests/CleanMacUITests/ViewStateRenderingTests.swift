import AppKit
import CleanMacCore
import SwiftUI
import XCTest
@testable import CleanMac

/// Renders the real `ContentView` composition with a *populated* store across the
/// data-bearing pages and languages. The existing smoke test only covers an empty
/// store, so these exercise the results table, uninstall plans, AI output and
/// localized chrome that an empty store never reaches.
@MainActor
final class ViewStateRenderingTests: XCTestCase {
    private let contentRect = CGRect(x: 260, y: 80, width: 840, height: 560)

    func testCleanUpPageRendersPopulatedResults() throws {
        let store = makeStoreWithCandidates(language: .english)
        let image = render(ContentView(store: store, initialSelection: .cleanUp, languageOverride: .english))
        try assertContentIsVisible(image, "Clean up page rendered blank with candidates present")
    }

    func testCleanUpPageRendersInChinese() throws {
        let store = makeStoreWithCandidates(language: .chinese)
        let image = render(ContentView(store: store, initialSelection: .cleanUp, languageOverride: .chinese))
        try assertContentIsVisible(image, "Clean up page rendered blank in Chinese")
    }

    func testDuplicatesPageRendersDuplicateGroups() throws {
        let store = makeStoreWithDuplicates(language: .english)
        let image = render(ContentView(store: store, initialSelection: .duplicates, languageOverride: .english))
        try assertContentIsVisible(image, "Duplicates page rendered blank with duplicate groups present")
    }

    func testUninstallerPageRendersPlans() throws {
        let store = makeStoreWithUninstallPlans(language: .english)
        let image = render(ContentView(store: store, initialSelection: .uninstaller, languageOverride: .english))
        try assertContentIsVisible(image, "Uninstaller page rendered blank with plans present")
    }

    func testAIReviewPageRendersOutput() throws {
        let store = makeStoreWithCandidates(language: .english)
        store.aiOutput = """
        {
          "summary": "Two cache files are safe to remove.",
          "safe_to_delete": ["/Users/me/Library/Caches/com.example/blob.cache"],
          "needs_user_review": ["/Users/me/Downloads/installer.dmg"]
        }
        """
        store.status = .aiReviewFinished
        let image = render(ContentView(store: store, initialSelection: .aiReview, languageOverride: .english))
        try assertContentIsVisible(image, "AI review page rendered blank with output present")
    }

    func testAIReviewPageRendersErrorMessageAfterFailure() throws {
        let store = makeStoreWithCandidates(language: .english)
        store.errorMessage = .system("AI command exited with code 1: something went wrong")
        store.status = .aiReviewFailed
        let image = render(ContentView(store: store, initialSelection: .aiReview, languageOverride: .english))
        try assertContentIsVisible(image, "AI review page rendered blank with a failure error message present")
    }

    func testDiskOverviewRendersAfterScanReport() throws {
        let store = makeStoreWithCandidates(language: .english)
        let image = render(ContentView(store: store, initialSelection: .diskOverview, languageOverride: .english))
        try assertContentIsVisible(image, "Disk overview rendered blank after a scan report")
    }

    func testAIReviewPageRendersToolSelectionPills() throws {
        let store = CleaningStore(
            language: .english,
            aiToolDetector: AIToolDetector(locator: FakeAIToolLocator(found: ["codex": "/opt/homebrew/bin/codex"]))
        )
        let candidates = sampleCandidates()
        store.candidates = candidates
        store.lastReport = ScanReport(
            candidates: candidates,
            duplicateGroups: [],
            totalBytes: candidates.reduce(0) { $0 + $1.sizeBytes },
            scannedFileCount: candidates.count,
            skippedFileCount: 0
        )
        store.selection.selectMovable(candidates)
        store.selectedCandidateID = candidates.first?.id
        store.status = .candidatesFound(candidates.count)

        let image = render(ContentView(store: store, initialSelection: .aiReview, languageOverride: .english))
        try assertContentIsVisible(image, "AI review page rendered blank with a detected tool present")
    }

    // MARK: - Store fixtures

    private func makeStoreWithCandidates(language: ResolvedLanguage) -> CleaningStore {
        let store = CleaningStore(language: language)
        let candidates = sampleCandidates()
        store.candidates = candidates
        store.lastReport = ScanReport(
            candidates: candidates,
            duplicateGroups: [],
            totalBytes: candidates.reduce(0) { $0 + $1.sizeBytes },
            scannedFileCount: candidates.count,
            skippedFileCount: 0
        )
        store.selection.selectMovable(candidates)
        store.selectedCandidateID = candidates.first?.id
        store.status = .candidatesFound(candidates.count)
        return store
    }

    private func makeStoreWithDuplicates(language: ResolvedLanguage) -> CleaningStore {
        let store = CleaningStore(language: language)
        let original = candidate(
            path: "/Users/me/Pictures/photo.raw",
            size: 8_000_000,
            category: .largeFile,
            modifiedAt: Date(timeIntervalSince1970: 1_700_000_200),
            protection: .allowed
        )
        let copy = candidate(
            path: "/Users/me/Downloads/photo-copy.raw",
            size: 8_000_000,
            category: .downloads,
            modifiedAt: Date(timeIntervalSince1970: 1_700_000_100),
            protection: .allowed
        )
        let group = DuplicateFileGroup(contentHash: "abc123", sizeBytes: 8_000_000, candidates: [original, copy])
        let candidates = [original, copy]
        store.candidates = candidates
        store.lastReport = ScanReport(
            candidates: candidates,
            duplicateGroups: [group],
            totalBytes: 16_000_000,
            scannedFileCount: 2,
            skippedFileCount: 0
        )
        store.selectedCandidateID = original.id
        store.status = .candidatesFound(candidates.count)
        return store
    }

    private func makeStoreWithUninstallPlans(language: ResolvedLanguage) -> CleaningStore {
        let store = CleaningStore(language: language)
        let appCandidate = candidate(
            path: "/Applications/Demo.app",
            size: 64_000_000,
            category: .application,
            isDirectory: true,
            protection: .requiresReview,
            rules: ["Application bundle: review with support files"]
        )
        let support = candidate(
            path: "/Users/me/Library/Caches/com.example.demo",
            size: 3_000_000,
            category: .applicationSupport,
            isDirectory: true,
            protection: .requiresReview,
            rules: ["App uninstall support item"]
        )
        let plan = AppUninstallPlan(
            appName: "Demo",
            bundleIdentifier: "com.example.demo",
            appCandidate: appCandidate,
            supportCandidates: [support]
        )
        store.uninstallPlans = [plan]
        store.candidates = plan.allCandidates
        store.lastReport = ScanReport(
            candidates: plan.allCandidates,
            duplicateGroups: [],
            totalBytes: plan.reclaimableBytes,
            scannedFileCount: plan.allCandidates.count,
            skippedFileCount: 0
        )
        store.selectedCandidateID = appCandidate.id
        store.status = .candidatesFound(plan.allCandidates.count)
        return store
    }

    private func sampleCandidates() -> [CleaningCandidate] {
        [
            candidate(
                path: "/Users/me/Downloads/installer.dmg",
                size: 4_200_000,
                category: .downloads,
                modifiedAt: Date(timeIntervalSince1970: 1_700_000_000),
                protection: .requiresReview,
                rules: ["Downloads: review before moving"]
            ),
            candidate(
                path: "/Users/me/Library/Caches/com.example/blob.cache",
                size: 900_000,
                category: .cache,
                protection: .allowed,
                rules: ["Cache: usually rebuildable"]
            ),
            candidate(
                path: "/Users/me/Movies/export.mov",
                size: 1_500_000_000,
                category: .largeFile,
                protection: .requiresReview,
                rules: ["Large file: not automatically safe"]
            )
        ]
    }

    private func candidate(
        path: String,
        size: Int64,
        category: CandidateCategory,
        modifiedAt: Date? = nil,
        isDirectory: Bool = false,
        protection: DeletionProtection = .requiresReview,
        rules: [String] = []
    ) -> CleaningCandidate {
        CleaningCandidate(
            url: URL(filePath: path),
            sizeBytes: size,
            modifiedAt: modifiedAt,
            category: category,
            risk: .reviewRecommended,
            reasons: ["Sample candidate"],
            isDirectory: isDirectory,
            protection: protection,
            ruleMatches: [],
            userVisibleRules: rules
        )
    }

    // MARK: - Rendering helpers

    private func render(_ view: some View, width: CGFloat = 1_180, height: CGFloat = 760) -> NSImage {
        let hostingView = NSHostingView(rootView: view.frame(width: width, height: height))
        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: height)
        hostingView.layoutSubtreeIfNeeded()

        let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds)!
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)

        let image = NSImage(size: hostingView.bounds.size)
        image.addRepresentation(representation)
        return image
    }

    private func assertContentIsVisible(
        _ image: NSImage,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let brightness = try averageBrightness(of: image, in: contentRect)
        XCTAssertGreaterThan(brightness, 0.08, message, file: file, line: line)
    }

    private func averageBrightness(of image: NSImage, in rect: CGRect) throws -> Double {
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            XCTFail("Unable to read rendered image data")
            return 0
        }

        let minX = max(0, Int(rect.minX))
        let maxX = min(bitmap.pixelsWide, Int(rect.maxX))
        let minY = max(0, Int(rect.minY))
        let maxY = min(bitmap.pixelsHigh, Int(rect.maxY))
        var total = 0.0
        var count = 0

        for y in stride(from: minY, to: maxY, by: 20) {
            for x in stride(from: minX, to: maxX, by: 20) {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { continue }
                total += (Double(color.redComponent) + Double(color.greenComponent) + Double(color.blueComponent)) / 3.0
                count += 1
            }
        }

        guard count > 0 else {
            XCTFail("No pixels sampled from rendered image")
            return 0
        }
        return total / Double(count)
    }
}

private struct FakeAIToolLocator: ExecutableLocating {
    let found: [String: String]

    func locate(_ binaryName: String) -> String? {
        found[binaryName]
    }
}
