// main.swift
// Localizables

import Foundation
import Parsing

let commentParser = Parse {
    "/*"
    Skip {
        PrefixThrough("*/")
    }
}

let interStringsParser = Parse {
    Skip {
        Many {
            OneOf {
                commentParser
                Newline()
            }
        }
    }
}

let keyParse = Parse {
    "\""
    PrefixUpTo("\"").map(String.init)
    "\""
}

let valueParse = Parse {
    "\""
    PrefixUpTo("\";").map(String.init)
    "\";"
}

let keysParser = Parse {
    interStringsParser
    keyParse
    " = "
    valueParse
}

let manyKeys = Many {
    keysParser
} separator: {
    interStringsParser
}

let keys: [(key: String, value: String)] = try manyKeys.parse(allLiterals)

for (key, value) in keys {
    print(key, value)
}
