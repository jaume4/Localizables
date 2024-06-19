// LiteralsUpdater.swift
// Localizables

import Foundation

public struct LiteralsFile {
    public let url: URL
    public private(set) var literals: [String: String]
    public private(set) var missingKeys: [String]

    var keys: Dictionary<String, String>.Keys {
        literals.keys
    }

    public init(url: URL) async throws {
        self.url = url
        missingKeys = []

        guard let literals = try NSDictionary(contentsOf: url, error: ()) as? [String: String] else {
            throw "Cant read file \(url)"
        }

        self.literals = literals
    }

    /// Updates any found existing key from the origin file.
    /// If a key is not found, it will keep the original value
    /// - Parameter origin: Origin file
    public mutating func update(with origin: LiteralsFile) {
        var foundKeys: Set<String> = []
        foundKeys.reserveCapacity(literals.count)

        var mergedLiterals: [String: String] = [:]
        mergedLiterals.reserveCapacity(literals.count)

        for (key, value) in origin.literals {
            if keys.contains(key) {
                foundKeys.insert(key)
                mergedLiterals[key] = value
            }
        }

        missingKeys = Set(keys).subtracting(foundKeys)
            .sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })

        if !missingKeys.isEmpty { // If we have missing literals, find them on the original one
            for (key, value) in literals {
                if foundKeys.insert(key).inserted {
                    mergedLiterals[key] = value
                }
            }
        }

        literals = mergedLiterals // overwrite literals with the merged ones
    }

    public func save() throws {
        let sortedKeys = keys.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })
        let outputString = sortedKeys.reduce(into: "") { output, key in
            output.append("\"\(key)\"=\"\(literals[key]!)\";\n")
        }
        let temporalFileURL = url.appendingPathExtension(".orig")

        try FileManager.default.moveItem(at: url, to: temporalFileURL)

        try Data(String(outputString).utf8).write(to: url)

        try FileManager.default.removeItem(at: temporalFileURL)
    }
}
