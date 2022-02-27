// extensions.swift
// Localizables

import Foundation

extension URL {
    var fileURL: URL {
        if scheme == nil {
            return URL(string: "file://" + absoluteString)!
        } else {
            return self
        }
    }

    var terminalPath: String {
        absoluteString.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " ")
    }
}

extension UInt8 {
    static let quote: UInt8 = .init(ascii: "\"")
    static let semicolon: UInt8 = .init(ascii: ";")
    static let newLine: UInt8 = 0xA
    static let backslah: UInt8 = .init(ascii: "\\")
    static let space: UInt8 = .init(ascii: " ")
    static let equal: UInt8 = .init(ascii: "=")
}
