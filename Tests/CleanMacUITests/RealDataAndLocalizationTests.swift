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

    private func sourceFile(_ relativePath: String) throws -> String {
        let root = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(contentsOf: root.appending(path: relativePath), encoding: .utf8)
    }
}
