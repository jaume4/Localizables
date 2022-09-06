// LiteralsUpdater.swift
// Localizables

import Foundation
import Parsing

public typealias Literal = (key: String, value: String)

public struct LiteralsFile {
    public let url: URL
    public private(set) var literals: [Literal]
    public let duplicatedKeys: Set<String>
    public let keys: Set<String>
    public private(set) var missingKeys: [String]

    public init(url: URL) async throws {
        self.url = url
        missingKeys = []

        let string = try String(contentsOf: url)
        literals = try LocalizablesParser.parse(from: string)
            .sorted(by: { $0.key.caseInsensitiveCompare($1.key) == .orderedAscending })
        (duplicatedKeys, keys) = Self.calculateDuplicates(from: literals)
    }

    /// Updates any found existing key from the origin file.
    /// If a key is not found, it will keep the original value
    /// - Parameter origin: Origin file
    public mutating func update(with origin: LiteralsFile) {
        var foundKeys: Set<String> = []
        foundKeys.reserveCapacity(literals.count)

        var mergedLiterals: [Literal] = []
        mergedLiterals.reserveCapacity(literals.count)

        for (key, value) in origin.literals {
            if keys.contains(key), foundKeys.insert(key).inserted {
                mergedLiterals.append((key, value))
            }
        }

        missingKeys = keys.subtracting(foundKeys)
            .sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })

        if !missingKeys.isEmpty { // If we have missing literals, find them on the original one
            for (key, value) in literals {
                if foundKeys.insert(key).inserted {
                    mergedLiterals.append((key, value))
                }
            }
        }

        literals = mergedLiterals // overwrite literals with the merged ones and sort them
            .sorted(by: { $0.key.caseInsensitiveCompare($1.key) == .orderedAscending })
    }

    public func save() throws {
        let outputString = try LocalizablesParser.generateOutput(from: literals)
        let temporalFileURL = url.appendingPathExtension(".orig")

        try FileManager.default.moveItem(at: url, to: temporalFileURL)

        try Data(String(outputString).utf8).write(to: url)

        try FileManager.default.removeItem(at: temporalFileURL)
    }

    static func calculateDuplicates(from literals: [Literal]) -> (duplicates: Set<String>, unique: Set<String>) {
        var uniqueKeys: Set<String> = Set(minimumCapacity: literals.count)

        let duplicatedKeys = Set(literals
            .map(\.key)
            .filter { !uniqueKeys.insert($0).inserted })

        return (duplicatedKeys, uniqueKeys)
    }
}
