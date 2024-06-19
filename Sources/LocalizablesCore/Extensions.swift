// Extensions.swift
// Localizables

import Foundation

extension String: Error {}

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        write(Data(string.utf8))
    }
}
