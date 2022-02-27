// Extensions.swift
// Localizables

import Foundation

public extension URL {
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
    @usableFromInline
    static let quote: UInt8 = .init(ascii: "\"")
    @usableFromInline
    static let semicolon: UInt8 = .init(ascii: ";")
    @usableFromInline
    static let newLine: UInt8 = 0xA
    @usableFromInline
    static let backslash: UInt8 = .init(ascii: "\\")
    @usableFromInline
    static let space: UInt8 = .init(ascii: " ")
    @usableFromInline
    static let equal: UInt8 = .init(ascii: "=")
}
