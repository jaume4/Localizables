// parser.swift
// Localizables

import Foundation
import Parsing

enum LiteralsParser {
    private static let commentParser = Parse {
        "/*"
        Skip {
            PrefixThrough("*/")
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
        "\""
        PrefixUpTo("\"").map(String.init)
        "\""
    }

    private static let valueParse = Parse {
        "\""
        PrefixUpTo("\";").map(String.init)
        "\";"
    }

    private static let keysParser = Parse {
        interStringsParser
        keyParse
        " = "
        valueParse
    }

    private static let manyKeys = Many {
        keysParser
    } separator: {
        interStringsParser
    }

    static func parse(from string: String) throws -> [(key: String, value: String)] {
        try manyKeys.parse(string)
    }
}
