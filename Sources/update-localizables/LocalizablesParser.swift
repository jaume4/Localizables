// LocalizablesParser.swift
// Localizables

import Foundation
import Parsing

public enum LocalizablesParser {
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
            Newline()
        }
    }

    static let interStringsParser = Parse {
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

    @usableFromInline
    static let manyKeys = Many(atLeast: 1) {
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

    @inlinable
    @inline(__always)
    public static func parse(from string: String) throws -> [Literal] {
        try fileParser.parse(string[...].utf8)
    }
}
