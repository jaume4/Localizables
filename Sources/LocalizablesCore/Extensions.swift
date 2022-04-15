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
