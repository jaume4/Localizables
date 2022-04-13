// LiteralsUpdater.swift
// Localizables

import Foundation
import Parsing

public typealias Literal = (key: String, value: String)

public struct LiteralsReader {
    public let url: URL
    public private(set) var literals: [Literal]
    public let duplicatedKeys: Set<String>
    public let keys: Set<String>

    public init(url: URL) async throws {
        self.url = url

        let string = try String(contentsOf: url)
        literals = try LocalizablesParser.parse(from: string)
            .sorted(by: { $0.key.caseInsensitiveCompare($1.key) == .orderedAscending })
        (duplicatedKeys, keys) = Self.calculateDuplicates(from: literals)
    }

    public mutating func update(from origin: LiteralsReader) -> Set<String> {
        var foundKeys: Set<String> = []
        foundKeys.reserveCapacity(literals.count)

        var mergedLiterals: [Literal] = []
        mergedLiterals.reserveCapacity(literals.count)

        for (key, value) in origin.literals {
            if keys.contains(key), foundKeys.insert(key).inserted {
                mergedLiterals.append((key, value))
            }
        }

        let missingKeys = keys.subtracting(foundKeys)

        if !missingKeys.isEmpty { // If we have missing literals, find them on the original one
            for (key, value) in literals {
                if foundKeys.insert(key).inserted {
                    mergedLiterals.append((key, value))
                }
            }
        }

        let sorted = mergedLiterals
            .sorted(by: { $0.key.caseInsensitiveCompare($1.key) == .orderedAscending })

        literals = sorted

        return missingKeys
    }

    public func save() async throws {
        let outputString = try LocalizablesParser.generateOutput(from: literals)
        let temporalFileURL = url.appendingPathExtension(".orig")

        try FileManager.default.moveItem(at: url, to: temporalFileURL)

        try Data(outputString).write(to: url)

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
