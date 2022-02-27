// LocalizableLineParser.swift
// Localizables

import Foundation
import Parsing

@usableFromInline
struct LocalizableLineParser: Parser {
    @inlinable
    @inline(__always)
    func parse(_ input: inout Substring.UTF8View) throws -> Literal {
        guard input.first == .quote else {
            throw ParsingError(description: "Line does not start with \"")
        }

        input.removeFirst()

        let key = input.prefix {
            $0 != .quote
        }

        input.removeFirst(key.count + 1)

        var foundEqual = false

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

        input.removeFirst(startOfValue.count + 1)

        var latest: UInt8 = 0
        var foundCloseQuote = false
        var foundCloseSemicolon = false

        var index = 0
        var valueEndPosition = 0

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
                // that's it
                foundCloseSemicolon = true
                return false
            case (true, false) where value != .semicolon && value != .space:
                throw ParsingError(description: "Unexpected character found after closing \": \(Character(UnicodeScalar(value)))")
            default: break
            }

            return true
        }

        let endIndex = input.index(input.startIndex, offsetBy: valueEndPosition)

        let value = input[..<endIndex]

        input.removeFirst(index)

        guard let key = String(key), let value = String(value) else {
            throw ParsingError(description: "Can't get string value")
        }

        return (key, value)
    }
}
