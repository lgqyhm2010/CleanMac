import XCTest
@testable import CleanMacCore

final class MenuBarMonitorSummaryTests: XCTestCase {
    func testTitleShowsScanningBeforeCandidateCount() {
        XCTAssertEqual(
            MenuBarMonitorSummary.title(status: .candidatesFound(12), candidateCount: 12, isScanning: true),
            "Scanning..."
        )
    }

    func testTitleShowsCandidateCountWhenResultsExist() {
        XCTAssertEqual(
            MenuBarMonitorSummary.title(status: .candidatesFound(12), candidateCount: 12, isScanning: false),
            "12 items"
        )
    }

    func testTitleShowsCleanMacForIdleOrEmptyResults() {
        XCTAssertEqual(
            MenuBarMonitorSummary.title(status: .ready, candidateCount: 0, isScanning: false),
            "CleanMac"
        )
        XCTAssertEqual(
            MenuBarMonitorSummary.title(status: .candidatesFound(0), candidateCount: 0, isScanning: false),
            "CleanMac"
        )
    }
}
