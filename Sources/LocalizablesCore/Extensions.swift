// Extensions.swift
// Localizables

import Foundation

extension Substring.Element {
    @usableFromInline
    static let quote: Character = "\""
    @usableFromInline
    static let semicolon: Character = ";"
    @usableFromInline
    static let backslash: Character = "\\"
    @usableFromInline
    static let space: Character = " "
    @usableFromInline
    static let equal: Character = "="
}

extension String: Error {}

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        write(Data(string.utf8))
    }
}
