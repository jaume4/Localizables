// LiteralsUpdater.swift
// Localizables

import Foundation
import Parsing

public typealias Literal = (key: String, value: String)

public struct LiteralsUpdater {
    let originURL: URL
    let destinationURL: URL
    var mergedLiterals: [Literal]

    public init(originURL: URL, destinationURL: URL) {
        self.originURL = originURL
        self.destinationURL = destinationURL
        mergedLiterals = []
    }

    @discardableResult
    public mutating func run() throws -> Info {
        let destinationLiterals = try readLiterals(from: destinationURL)

        print("found \(destinationLiterals.count) literals on destination file")

        let (duplicatedKeys, destinationKeys) = calculateDuplicates(from: destinationLiterals)

        let newLiterals = try readLiterals(from: originURL)

        print("found \(newLiterals.count) literals on origin file")

        let (mergedLiterals, missingKeys) = merge(destination: destinationLiterals,
                                                  destinationKeys: destinationKeys,
                                                  new: newLiterals)

        self.mergedLiterals = mergedLiterals

        let info = Info(duplicatedKeys: duplicatedKeys, updatedKeys: mergedLiterals, missingKeys: Array(missingKeys).sorted())

        return info
    }

    func calculateDuplicates(from literals: [Literal]) -> (duplicates: [String], unique: Set<String>) {
        var uniqueKeys: Set<String> = Set(minimumCapacity: literals.count)

        let duplicatedKeys = literals
            .map(\.key)
            .filter { !uniqueKeys.insert($0).inserted }

        if !duplicatedKeys.isEmpty {
            print("warning, found \(duplicatedKeys.count) duplicated keys found, unique keys: \(uniqueKeys.count)")
            print("\n----------------")
            print(duplicatedKeys.joined(separator: "\n"))
            print("---------------\n")
        }

        return (duplicatedKeys, uniqueKeys)
    }

    func merge(destination: [Literal], destinationKeys: Set<String>, new: [Literal]) -> (mergedLiterals: [Literal], missingKeys: Set<String>) {
        var foundKeys: Set<String> = []
        var mergedLiterals: [Literal] = []

        for (key, value) in new {
            if destinationKeys.contains(key), foundKeys.insert(key).inserted {
                mergedLiterals.append((key, value))
            }
        }

        let missingKeys = destinationKeys.subtracting(foundKeys)

        if !missingKeys.isEmpty { // If we have missing literals, find them on the original one
            print("warning, missing keys found: \(missingKeys.count)")
            print("\n----------------")
            print(missingKeys.lazy.joined(separator: "\n"))
            print("---------------\n")

            for (key, value) in destination {
                if foundKeys.insert(key).inserted {
                    mergedLiterals.append((key, value))
                }
            }
        }

        let sorted = mergedLiterals
            .sorted(by: { $0.key.caseInsensitiveCompare($1.key) == .orderedAscending })

        return (sorted, missingKeys)
    }

    func readLiterals(from url: URL) throws -> [Literal] {
        let string = try String(contentsOf: url)
        return try LocalizablesParser.parse(from: string)
    }

    public func save() throws {
        try "".write(to: destinationURL, atomically: true, encoding: .utf8) // reset file
        let handle = try FileHandle(forWritingTo: destinationURL)

        for (key, value) in mergedLiterals {
            let string = "\"\(key)\" = \"\(value)\";\n"
            if #available(macOS 10.15.4, *) {
                try handle.write(contentsOf: Data(string.utf8))
            } else {
                handle.write(Data(string.utf8))
            }
        }

        try handle.close()
    }
}

public extension LiteralsUpdater {
    struct Info {
        public let duplicatedKeys: [String]
        public let updatedKeys: [Literal]
        public let missingKeys: [String]
    }
}
