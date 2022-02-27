// parser.swift
// Localizables

import Foundation
import Parsing

enum LiteralsParser {
    private static let commentParser = Parse {
        "/*".utf8
        Skip {
            PrefixThrough("*/".utf8)
        }
    }

    private static let interStringsParser = Parse {
        Skip {
            Many {
                OneOf {
                    commentParser
                    Newline()
                }
            }
        }
    }

    private static let keyParse = Parse {
        "\"".utf8
        PrefixUpTo("\"".utf8).compactMap(String.init)
        "\"".utf8
    }

    private static let valueParse = Parse {
        "\"".utf8
        PrefixUpTo("\";".utf8).compactMap(String.init)
        "\";".utf8
    }

    private static let keysParser = Parse {
        interStringsParser
        keyParse
        " = ".utf8
        valueParse
    }

    private static let manyKeys = Many {
        keysParser
    } separator: {
        interStringsParser
    }

    static func parse(from string: String) throws -> [(key: String, value: String)] {
        try manyKeys.parse(string[...].utf8)
    }
}
