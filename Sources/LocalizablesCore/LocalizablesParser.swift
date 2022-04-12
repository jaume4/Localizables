// LocalizablesParser.swift
// Localizables

import Foundation
import Parsing

enum LocalizablesParser {
    static let commentParser = Parse {
        "/*".utf8
        Skip {
            PrefixThrough("*/".utf8)
        }
    }

    static let slashCommentParser = Parse {
        Skip {
            Whitespace()
            "//".utf8
            Prefix { $0 != .newLine }
            Whitespace(1, .vertical)
        }
    }

    static let interStringsParser = Parse {
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
    public static func generateOutput(from literals: [Literal]) throws -> Substring.UTF8View {
        let value = try LocalizablesParser.Printer.print(literals)
        return value
    }

    @inlinable
    @inline(__always)
    public static func parse(from string: String) throws -> [Literal] {
        try fileParser.parse(string[...].utf8)
    }
}
