import AppKit
import CleanMacCore
import Foundation
import XCTest
@testable import CleanMac

final class RealDataAndLocalizationTests: XCTestCase {
    func testSidebarTextIsLocalizedForEverySupportedLanguage() {
        for language in ResolvedLanguage.allCases where language != .english {
            for section in SidebarSection.allCases {
                XCTAssertNotEqual(
                    section.title(language: language),
                    section.title(language: .english),
                    "\(section.rawValue) title is still English for \(language)"
                )
                XCTAssertNotEqual(
                    section.subtitle(language: language),
                    section.subtitle(language: .english),
                    "\(section.rawValue) subtitle is still English for \(language)"
                )
            }
        }
    }

    func testSidebarDoesNotStoreLocalizedCopyInSwiftLanguageBranches() throws {
        let source = try sourceFile("Sources/CleanMac/Views/SidebarSection.swift")

        XCTAssertFalse(source.contains("language == .chinese"))
        XCTAssertFalse(source.contains("language == .chineseTraditional"))
        XCTAssertFalse(source.contains("return title"))
    }

    func testOverviewSourcesDoNotContainFakeCapacityLiterals() throws {
        let scanSource = try sourceFile("Sources/CleanMac/Views/ScanView.swift")
        let sidebarSource = try sourceFile("Sources/CleanMac/Views/SidebarView.swift")
        let combinedSource = scanSource + "\n" + sidebarSource

        let fakeLiterals = [
            "428 GB",
            "72 GB",
            "500 GB",
            "5.1 GB",
            "32 GB",
            "20 GB",
            "30 GB",
            "12 GB",
            "75 GB",
            "120 GB",
            "38 GB",
            "50 GB",
            "35 GB",
            "10.2 GB",
            "15 GB",
            "6.4 GB",
            "20_000_000_000",
            "32_000_000_000"
        ]

        for literal in fakeLiterals {
            XCTAssertFalse(
                combinedSource.contains(literal),
                "Overview UI still contains fake capacity literal \(literal)"
            )
        }
    }

    func testSidebarTabIconAnimationIsDrivenByHoverOnly() throws {
        let source = try sourceFile("Sources/CleanMac/Views/SidebarView.swift")

        XCTAssertTrue(source.contains("@State private var hoveredSection: SidebarSection?"))
        XCTAssertTrue(source.contains("let isHovered = hoveredSection == section"))
        XCTAssertTrue(source.contains("let shouldAnimateIcon = isHovered && !isSelected"))
        XCTAssertTrue(source.contains("CleanMacFeatureImage(asset: section.illustrationAsset, tint: tint, isActive: shouldAnimateIcon)"))
        XCTAssertTrue(source.contains("hoveredSection = nil"))
        XCTAssertTrue(source.contains(".onHover"))
        XCTAssertFalse(source.contains("CleanMacFeatureImage(asset: section.illustrationAsset, tint: tint, isActive: isHovered)"))
        XCTAssertFalse(source.contains("CleanMacFeatureImage(asset: section.illustrationAsset, tint: tint, isActive: isSelected)"))
    }

    func testFeatureImagesResetWithoutAnimatingWhenInactive() throws {
        let source = try sourceFile("Sources/CleanMac/Views/DesignSystem.swift")

        XCTAssertTrue(source.contains("TimelineView(.animation)"))
        XCTAssertTrue(source.contains("let progress = animationProgress(at: timeline.date)"))
        XCTAssertTrue(source.contains("return 0"))
        XCTAssertFalse(source.contains("@State private var floating = false"))
        XCTAssertFalse(source.contains("@State private var pulsing = false"))
        XCTAssertFalse(source.contains("withAnimation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.float))"))
        XCTAssertFalse(source.contains(".animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.float), value: floating)"))
    }

    func testScrollingSurfacesAvoidAlwaysOnIllustrationWork() throws {
        let source = try sourceFile("Sources/CleanMac/Views/DesignSystem.swift")

        XCTAssertTrue(source.contains("LazyVStack(alignment: .leading, spacing: CleanMacTheme.sectionSpacing)"))
        XCTAssertTrue(source.contains("private final class CleanMacIllustrationImageCache"))
        XCTAssertTrue(source.contains("CleanMacIllustrationImageCache.shared.image(for: asset)"))
        XCTAssertTrue(source.contains("private var isAnimating: Bool"))
        XCTAssertTrue(source.contains("featureContent(progress: 0)"))
        XCTAssertTrue(source.contains("iconContent(progress: 0)"))
        XCTAssertFalse(source.contains(".easeInOut(duration: 1.8).delay(delay).repeatForever"))
    }

    func testDuplicateHashingStaysOffTheMainActorAfterStoreMutations() throws {
        let source = try sourceFile("Sources/CleanMac/Stores/CleaningStore.swift")

        XCTAssertTrue(source.contains("nonisolated private static func duplicateGroupsOffMainActor"))
        XCTAssertTrue(source.contains("await Self.duplicateGroupsOffMainActor(for: candidates)"))
        XCTAssertFalse(source.contains("let duplicateGroups = (try? DuplicateFileFinder().findDuplicates(in: candidates)) ?? []"))
    }

    func testAIReviewShowsDisclosureLimitAndCancellationControls() throws {
        let source = try sourceFile("Sources/CleanMac/Views/AIReviewView.swift")
        let storeSource = try sourceFile("Sources/CleanMac/Stores/CleaningStore.swift")

        XCTAssertTrue(source.contains("L10n.text(.aiPrivacyDisclosure"))
        XCTAssertTrue(source.contains("L10n.text(.aiSelectionLimitMessage"))
        XCTAssertTrue(source.contains("store.cancelAIReview()"))
        XCTAssertTrue(storeSource.contains("aiReviewTask?.cancel()"))
        XCTAssertTrue(storeSource.contains("AIReviewService.maximumCandidateCount"))
    }

    func testReimaginedDashboardUsesPaperChromeAndTrustStrip() throws {
        let contentSource = try sourceFile("Sources/CleanMac/Views/ContentView.swift")
        let designSystemSource = try sourceFile("Sources/CleanMac/Views/DesignSystem.swift")
        let sidebarSource = try sourceFile("Sources/CleanMac/Views/SidebarView.swift")
        let scanSource = try sourceFile("Sources/CleanMac/Views/ScanView.swift")

        XCTAssertTrue(contentSource.contains("private let languageOverride: ResolvedLanguage?"))
        XCTAssertTrue(contentSource.contains("languageOverride ?? AppLanguage(storedRawValue: appLanguageRaw).resolved()"))
        XCTAssertTrue(contentSource.contains("CleanMacAppTitleBar("))
        XCTAssertTrue(contentSource.contains("openSettings: { selection = .settings }"))

        XCTAssertTrue(designSystemSource.contains("static let sidebar = paper"))
        XCTAssertTrue(designSystemSource.contains("static let sidebarText = secondaryText"))
        XCTAssertTrue(designSystemSource.contains("Bundle.module.url(forResource: asset.rawValue, withExtension: \"png\")"))
        XCTAssertTrue(designSystemSource.contains("private struct TrafficLightDot"))
        XCTAssertTrue(designSystemSource.contains("CleanMacFeatureImage(asset: .mascot"))
        XCTAssertTrue(designSystemSource.contains("Button(action: openSettings)"))
        XCTAssertTrue(designSystemSource.contains("L10n.text(.help"))
        XCTAssertFalse(designSystemSource.contains("subdirectory: \"Images\""))
        XCTAssertFalse(designSystemSource.contains(".blur(radius: 70)"))
        XCTAssertFalse(designSystemSource.contains(".blur(radius: 80)"))

        XCTAssertTrue(sidebarSource.contains("CleanMacTheme.sidebarSelectedFill"))
        XCTAssertTrue(sidebarSource.contains("CleanMacTheme.sidebarDivider"))
        XCTAssertFalse(sidebarSource.contains("Color.white.opacity(0.12)"))
        XCTAssertFalse(sidebarSource.contains("foregroundStyle(isSelected ? Color.white"))

        XCTAssertTrue(scanSource.contains("private struct TrustBadgeStrip"))
        XCTAssertTrue(scanSource.contains("private struct DashboardHeaderRow"))
        XCTAssertTrue(scanSource.contains("DashboardHeaderRow(language: language)"))
        XCTAssertTrue(scanSource.contains("private struct DiskOverviewDashboardCard"))
        XCTAssertTrue(scanSource.contains("DashboardScanCTA("))
        XCTAssertTrue(scanSource.contains("OverviewFeatureGrid("))
        XCTAssertTrue(scanSource.contains("LazyVGrid(columns: Self.columns"))
        XCTAssertFalse(scanSource.contains("DiskOverviewHeader(store: store"))
        XCTAssertTrue(scanSource.contains("TrustBadgeStrip(language: language)"))
        XCTAssertTrue(scanSource.contains("L10n.text(.trustInstalledAICLI"))
        XCTAssertTrue(scanSource.contains("L10n.text(.trustNoTelemetry"))
        XCTAssertTrue(scanSource.contains("L10n.text(.trustAIProviderNetwork"))
    }

    func testReimaginedDashboardIllustrationsCannotFallBackToSystemSymbols() throws {
        let designSystemSource = try sourceFile("Sources/CleanMac/Views/DesignSystem.swift")

        XCTAssertTrue(designSystemSource.contains("CleanMacIllustrationImageCache.shared.image(for: asset)"))
        XCTAssertTrue(designSystemSource.contains("Image(nsImage: image)"))
        XCTAssertFalse(designSystemSource.contains("fallbackSymbolName"))
        XCTAssertFalse(designSystemSource.contains("CleanMacPulseIcon(symbolName: asset."))
        XCTAssertFalse(designSystemSource.contains("Image(systemName: asset."))
    }

    func testReimaginedDashboardIllustrationPNGsExistForEveryAsset() throws {
        let resourcesURL = packageRoot().appending(path: "Sources/CleanMac/Resources/Images")
        let expectedAssets = [
            "cleanmac-mascot",
            "feature-disk-overview",
            "feature-speed-up",
            "feature-cleanup-trash",
            "feature-manage-space",
            "feature-duplicates",
            "feature-app-uninstall",
            "feature-space-analysis",
            "feature-ai-review",
            "feature-permission-shield",
            "feature-settings"
        ]

        for asset in expectedAssets {
            let url = resourcesURL.appending(path: "\(asset).png")
            let data = try Data(contentsOf: url)

            XCTAssertEqual(Array(data.prefix(8)), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], "\(asset) is not a PNG")

            let image = try XCTUnwrap(NSImage(contentsOf: url), "\(asset) does not decode as NSImage")
            XCTAssertGreaterThanOrEqual(image.size.width, 512, "\(asset) is too small for dashboard feature art")
            XCTAssertGreaterThanOrEqual(image.size.height, 512, "\(asset) is too small for dashboard feature art")
        }
    }

    func testSidebarFunctionsUseDistinctIllustrationAssets() {
        let assetsBySection = Dictionary(
            uniqueKeysWithValues: SidebarSection.allCases.map { ($0, $0.illustrationAsset.rawValue) }
        )

        XCTAssertEqual(assetsBySection[.diskOverview], "feature-disk-overview")
        XCTAssertEqual(assetsBySection[.speedUp], "feature-speed-up")
        XCTAssertEqual(assetsBySection[.cleanUp], "feature-cleanup-trash")
        XCTAssertEqual(assetsBySection[.manageSpace], "feature-manage-space")
        XCTAssertEqual(assetsBySection[.duplicates], "feature-duplicates")
        XCTAssertEqual(assetsBySection[.uninstaller], "feature-app-uninstall")
        XCTAssertEqual(assetsBySection[.analyzeSpace], "feature-space-analysis")
        XCTAssertEqual(assetsBySection[.aiReview], "feature-ai-review")
        XCTAssertEqual(assetsBySection[.settings], "feature-settings")

        XCTAssertEqual(
            Set(assetsBySection.values).count,
            SidebarSection.allCases.count,
            "Every sidebar function should have its own illustration asset."
        )
    }

    func testSettingsAndUninstallerPagesUseFeatureSpecificArtwork() throws {
        let settingsSource = try sourceFile("Sources/CleanMac/Views/SettingsView.swift")
        let uninstallerSource = try sourceFile("Sources/CleanMac/Views/AppUninstallerView.swift")

        XCTAssertTrue(settingsSource.contains("asset: .settings"))
        XCTAssertFalse(settingsSource.contains("asset: .permissionShield"))
        XCTAssertTrue(uninstallerSource.contains("asset: .appUninstall"))
        XCTAssertFalse(uninstallerSource.contains("asset: .cleanupTrash"))
    }

    func testAppKitMenusUseLocalizedResources() throws {
        let source = try sourceFile("Sources/CleanMac/App/CleanMacApp.swift")
        let rawMenuLiterals = [
            "NSMenu(title: \"Edit\")",
            "withTitle: \"Undo\"",
            "withTitle: \"Redo\"",
            "withTitle: \"Cut\"",
            "withTitle: \"Copy\"",
            "withTitle: \"Paste\"",
            "withTitle: \"Select All\""
        ]

        for literal in rawMenuLiterals {
            XCTAssertFalse(source.contains(literal), "AppKit menu still hardcodes \(literal)")
        }
    }

    private func packageRoot() -> URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func sourceFile(_ relativePath: String) throws -> String {
        try String(contentsOf: packageRoot().appending(path: relativePath), encoding: .utf8)
    }
}
