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

    func testSplitFuzzNeverCrashesAndNeverInventsCharacters() {
        // Hammer the parser with random strings of the metacharacters it cares about
        // (quotes, backslashes, whitespace, unicode) and assert it always terminates,
        // returns non-nil tokens, and never produces more characters than it consumed
        // (quotes/escapes/separators can only be removed, never added).
        var generator = SeededGenerator(seed: 0xF0_0D_CAFE_1234_5678)
        let alphabet: [Character] = ["a", "b", " ", "\t", "\"", "'", "\\", "x", "报", "/", "-"]

        for _ in 0..<3_000 {
            let length = Int.random(in: 0...24, using: &generator)
            let input = String((0..<length).map { _ in alphabet.randomElement(using: &generator)! })

            let tokens = CommandLineArguments.split(input)

            let producedCharacters = tokens.reduce(0) { $0 + $1.count }
            XCTAssertLessThanOrEqual(
                producedCharacters,
                input.count,
                "split invented characters for input \(input.debugDescription)"
            )
        }
    }
}

/// Deterministic SplitMix64 generator so any fuzz failure reproduces from the seed.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed != 0 ? seed : 0x9E37_79B9_7F4A_7C15
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
