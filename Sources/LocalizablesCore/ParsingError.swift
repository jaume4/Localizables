// ParsingError.swift
// Localizables

import Foundation

public struct ParsingError: Error {
    @usableFromInline
    init(description: String) {
        self.description = description
    }

    public let description: String
}
