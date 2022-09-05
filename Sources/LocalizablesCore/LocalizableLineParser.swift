// LocalizableLineParser.swift
// Localizables

import Foundation
import Parsing

@usableFromInline
struct LocalizableLineParser: ParserPrinter {
    @inlinable
    @inline(__always)
    func print(_ output: (key: String, value: String), into input: inout Substring) throws {
        input.prepend(contentsOf: "\"" + output.key + #""=""# + output.value + "\";")
    }

    @inlinable
    @inline(__always)
    func parse(_ input: inout Substring) throws -> Literal {
        guard input.first == .quote else {
            throw ParsingError(description: "Line does not start with \"")
        }

        // skip first "
        input.removeFirst()

        // key goes till next "
        let key = input.prefix {
            $0 != .quote
        }

        input.removeFirst(key.count + 1)

        var foundEqual = false

        // find value starting quote: chars between the key quote and the value quote, allowing only spaces and one =
        // a comment could be in there but wtf
        let startOfValue = try input.prefix { value in

            switch foundEqual {
            case false where value == .space:
                break
            case false where value == .equal:
                foundEqual = true
            case true where value == .space:
                break
            case true where value == .quote:
                return false
            default:
                throw ParsingError(description: "Found unexpected character between key and value: \(String(value))")
            }

            return true
        }

        // remove till start of value
        input.removeFirst(startOfValue.count + 1)

        var latest: Character = .init(.init(0x0))
        var foundCloseQuote = false
        var foundCloseSemicolon = false

        var index = 0
        var valueEndPosition = 0

        // consume till we find the value end: quote + any spaces + ;
        // also keep track of escaped quotes to avoid mismatching the closing quote
        _ = try input.prefix { value in
            defer {
                latest = value
                index += 1
            }

            switch (foundCloseQuote, foundCloseSemicolon) {
            case (false, false) where latest != .backslash && value == .quote:
                // this is a unescaped quote, mark final position
                foundCloseQuote = true
                valueEndPosition = index
            case (true, false) where value == .semicolon:
                // that's it, found closing semicolon
                foundCloseSemicolon = true
                return false
            case (true, false) where value != .semicolon && value != .space:
                throw ParsingError(description: #"Unexpected character found after closing `"` -> ""# + "\(value))")
            default:
                // this is part of the value keep going
                break
            }

            return true
        }

        guard foundCloseQuote, foundCloseSemicolon else {
            throw ParsingError(description: "Unterminated value")
        }

        let endIndex = input.index(input.startIndex, offsetBy: valueEndPosition)

        let value = input[..<endIndex]

        input.removeFirst(index)

        return (String(key), String(value))
    }
}
