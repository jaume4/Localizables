// parser.swift
// Localizables

import Foundation
import Parsing

struct ParsingError: Error {
    let description: String
}

struct LiteralsParser: Parser {
    private init() {}

    @inlinable
    @inline(__always)
    static func parse(from string: String) throws -> [(key: String, value: String)] {
        try manyKeys.parse(string[...].utf8)
    }

    @inlinable
    @inline(__always)
    func parse(
        _ input: inout Substring.UTF8View
    ) throws -> (key: String, value: String) {
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
            default: throw ParsingError(description: "Found unexpected character between key and value: \(String(value))")
            }

            return true
        }

        input.removeFirst(startOfValue.count + 1)

        var latest: UInt8 = 0
        var foundCloseQuote = false
        var foundCloseSemicolon = false

        var index = 0
        var valueEndPosition = 0
        var lineEndPosition = 0

        _ = input.prefix { value in
            defer {
                latest = value
                index += 1
            }

            switch (foundCloseQuote, foundCloseSemicolon) {
            case (false, false) where latest != .backslah && value == .quote:
                foundCloseQuote = true
                valueEndPosition = index
            case (true, false) where value != .semicolon && value != .space:
                foundCloseQuote = false
            case (true, false) where value == .semicolon:
                foundCloseSemicolon = true
            case (true, true) where value == .newLine:
                lineEndPosition = index
                return false
            default: break
            }

            return true
        }

        let endIndex = input.index(input.startIndex, offsetBy: valueEndPosition)

        let value = input[..<endIndex]

        input.removeFirst(max(lineEndPosition, index))

        guard let key = String(key), let value = String(value) else {
            throw ParsingError(description: "Can't get string value")
        }

        return (key, value)
    }

    private static let commentParser = Parse {
        "/*".utf8
        Skip {
            PrefixThrough("*/".utf8)
        }
    }

    private static let slashCommentParser = Parse {
        Skip {
            Whitespace()
            "//".utf8
            Prefix { $0 != .newLine }
            Newline()
        }
    }

    private static let interStringsParser = Parse {
        Skip {
            Many {
                OneOf {
                    slashCommentParser
                    commentParser
                    Newline()
                }
            }
        }
    }

    private static let manyKeys = Many {
        interStringsParser
        LiteralsParser()
    } separator: {
        interStringsParser
    }
}
