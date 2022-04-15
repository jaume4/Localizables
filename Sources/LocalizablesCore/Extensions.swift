// Extensions.swift
// Localizables

import Foundation

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

extension String: Error {}

public extension String {
    var `default`: String { "\u{001B}[39m\(self)" }
    var red: String { "\u{001B}[31m\(self)\u{001B}[0m" }
    var green: String { "\u{001B}[32m\(self)\u{001B}[0m" }
    var yellow: String { "\u{001B}[33m\(self)\u{001B}[0m" }

    static let separator = "\n" + String(repeating: "-", count: 32)
}

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        write(Data(string.utf8))
    }
}
