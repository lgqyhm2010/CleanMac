import Foundation

enum CommandLineArguments {
    static func split(_ text: String) -> [String] {
        var result: [String] = []
        var current = ""
        // Tracks whether the current token has been started (even if still empty), so an
        // explicit empty quoted argument like "" or '' is preserved instead of dropped.
        var hasToken = false
        var quote: Character?
        var isEscaping = false

        func flush() {
            if hasToken {
                result.append(current)
            }
            current = ""
            hasToken = false
        }

        for character in text {
            if isEscaping {
                current.append(character)
                hasToken = true
                isEscaping = false
                continue
            }

            // Backslash escapes the next character everywhere except inside single quotes,
            // matching POSIX shell behavior (single quotes preserve backslashes literally).
            if character == "\\", quote != "'" {
                isEscaping = true
                continue
            }

            if character == "\"" || character == "'" {
                if quote == character {
                    quote = nil
                } else if quote == nil {
                    quote = character
                    hasToken = true
                } else {
                    current.append(character)
                    hasToken = true
                }
                continue
            }

            if character.isWhitespace, quote == nil {
                flush()
                continue
            }

            current.append(character)
            hasToken = true
        }

        flush()

        return result
    }
}
