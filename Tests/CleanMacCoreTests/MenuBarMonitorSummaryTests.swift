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
            "12 candidates"
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

    func testTitleLocalizesCompactStatus() {
        XCTAssertEqual(
            MenuBarMonitorSummary.title(status: .candidatesFound(3), candidateCount: 3, isScanning: false, language: .chinese),
            "3 个候选项"
        )
        XCTAssertEqual(
            MenuBarMonitorSummary.title(status: .movingToTrash, candidateCount: 3, isScanning: false, language: .chinese),
            "正在移动"
        )
        XCTAssertEqual(
            MenuBarMonitorSummary.title(status: .askingAI, candidateCount: 3, isScanning: false, language: .chinese),
            "AI 审查"
        )
    }
}
