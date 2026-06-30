import XCTest
@testable import CleanMac

final class CommandLineArgumentsTests: XCTestCase {
    func testSplitsPlainAndDoubleQuotedArguments() {
        XCTAssertEqual(CommandLineArguments.split("codex exec"), ["codex", "exec"])
        XCTAssertEqual(CommandLineArguments.split("--flag \"a b\""), ["--flag", "a b"])
    }

    func testPreservesBackslashesInsideSingleQuotes() {
        // POSIX shells treat backslash as a literal inside single quotes.
        XCTAssertEqual(CommandLineArguments.split("run 'a\\b'"), ["run", "a\\b"])
    }

    func testHonorsBackslashEscapesOutsideSingleQuotes() {
        // An escaped space stays part of the same argument.
        XCTAssertEqual(CommandLineArguments.split("a\\ b"), ["a b"])
        XCTAssertEqual(CommandLineArguments.split("say \"hi \\\"there\\\"\""), ["say", "hi \"there\""])
    }

    func testKeepsExplicitEmptyQuotedArguments() {
        XCTAssertEqual(CommandLineArguments.split("a '' b"), ["a", "", "b"])
        XCTAssertEqual(CommandLineArguments.split("\"\""), [""])
    }
}
