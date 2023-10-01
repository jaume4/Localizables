// LocalizablesParser.swift
// Localizables

import Foundation
import Parsing

enum LocalizablesParser {
    static let commentParser = Parse(input: Substring.self) {
        "/*"
        Skip {
            PrefixThrough("*/")
        }
    }

    static let slashCommentParser = Parse(input: Substring.self) {
        Skip {
            Whitespace()
            "//"
            Prefix { !$0.isNewline }
            Whitespace(1, .vertical)
        }
    }

    static let interStringsParser = Parse(input: Substring.self) {
        Skip {
            Many {
                OneOf {
                    slashCommentParser
                    commentParser
                    Whitespace(1, .vertical)
                }
            }
        }
    }

    @usableFromInline
    static let manyKeys = Many(1...) {
        LocalizableLineParser()
    } separator: {
        interStringsParser
    }

    @usableFromInline
    static let fileParser = Parse {
        interStringsParser
        manyKeys
        interStringsParser
        End()
    }

    @usableFromInline
    static let Printer = ParsePrint {
        Many {
            LocalizableLineParser()
        } separator: {
            Whitespace(1, .vertical)
        } terminator: {
            Whitespace(1, .vertical)
        }
    }

    @inlinable
    @inline(__always)
    public static func generateOutput(from literals: [Literal]) throws -> Substring {
        let value = try LocalizablesParser.Printer.print(literals)
        return value
    }

    @inlinable
    @inline(__always)
    public static func parse(from string: String) throws -> [Literal] {
        try fileParser.parse(string[...])
    }
}
