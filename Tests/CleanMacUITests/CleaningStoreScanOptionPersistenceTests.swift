import CleanMacCore
import XCTest
@testable import CleanMac

// File scope keeps these reachable from the nonisolated setUp/tearDown overrides.
private let minimumSizeKey = "scanMinimumSizeMegabytes"
private let largeFileThresholdKey = "scanLargeFileThresholdMegabytes"
private let includeHiddenFilesKey = "scanIncludeHiddenFiles"

private func clearStoredScanOptions() {
    for key in [minimumSizeKey, largeFileThresholdKey, includeHiddenFilesKey] {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

@MainActor
final class CleaningStoreScanOptionPersistenceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        clearStoredScanOptions()
    }

    override func tearDown() {
        clearStoredScanOptions()
        super.tearDown()
    }

    func testScanOptionsFallBackToTheDefaultsOnAFreshInstall() {
        let store = CleaningStore(language: .english)

        XCTAssertEqual(store.minimumSizeMegabytes, 10)
        XCTAssertEqual(store.largeFileThresholdMegabytes, 500)
        XCTAssertFalse(store.includeHiddenFiles)
    }

    func testScanOptionsPersistAcrossAppRelaunch() {
        let first = CleaningStore(language: .english)
        first.minimumSizeMegabytes = 42
        first.largeFileThresholdMegabytes = 1_500
        first.includeHiddenFiles = true

        let second = CleaningStore(language: .english)

        XCTAssertEqual(second.minimumSizeMegabytes, 42)
        XCTAssertEqual(second.largeFileThresholdMegabytes, 1_500)
        XCTAssertTrue(second.includeHiddenFiles)
    }

    func testAStoredMinimumSizeOfZeroSurvivesRelaunch() {
        let first = CleaningStore(language: .english)
        first.minimumSizeMegabytes = 0

        let second = CleaningStore(language: .english)

        XCTAssertEqual(second.minimumSizeMegabytes, 0, "0 MB is a real choice, not a missing preference")
    }

    func testStoredValuesOutsideTheSliderBoundsAreClamped() {
        UserDefaults.standard.set(9_999.0, forKey: minimumSizeKey)
        UserDefaults.standard.set(1.0, forKey: largeFileThresholdKey)

        let store = CleaningStore(language: .english)

        XCTAssertEqual(store.minimumSizeMegabytes, CleaningStore.minimumSizeRange.upperBound)
        XCTAssertEqual(store.largeFileThresholdMegabytes, CleaningStore.largeFileThresholdRange.lowerBound)
    }

    // Clamping cannot rescue a NaN: min/max propagate it, so both options need the
    // isFinite guard and both need pinning down.
    func testANonFiniteStoredMinimumSizeFallsBackToTheDefault() {
        UserDefaults.standard.set(Double.nan, forKey: minimumSizeKey)

        let store = CleaningStore(language: .english)

        XCTAssertEqual(store.minimumSizeMegabytes, 10, "a corrupt preference must not reach the slider as NaN")
    }

    func testANonFiniteStoredLargeFileThresholdFallsBackToTheDefault() {
        UserDefaults.standard.set(Double.nan, forKey: largeFileThresholdKey)

        let store = CleaningStore(language: .english)

        XCTAssertEqual(store.largeFileThresholdMegabytes, 500, "a corrupt preference must not reach the slider as NaN")
    }
}
