// LocalizableCommand.swift
// Localizables

import ArgumentParser
import Foundation
import LocalizablesCore

@main
struct LocalizableCommand: ParsableCommand {
    @Argument(help: "Path to the origin localizable file")
    var originFile: String

    @Argument(help: "Path to the target localizable file to update")
    var updatedFile: String

    mutating func run() throws {
        let originURL = URL(string: originFile.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!.fileURL
        let updatedFileURL = URL(string: updatedFile.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!.fileURL

        var original = try LiteralsReader(url: originURL)
        printInfo(literals: original, file: "origin")

        let updates = try LiteralsReader(url: updatedFileURL)
        printInfo(literals: updates, file: "updated")

        let missingKeys = original.update(from: updates)
            .sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })

        if !missingKeys.isEmpty {
            print("warning, missing keys found: \(missingKeys.count)")
            print("\n----------------")
            print(missingKeys.lazy.sorted().joined(separator: "\n"))
            print("---------------\n")
        }

        try original.save()
    }

    func printInfo(literals: LiteralsReader, file: String) {
        if !literals.duplicatedKeys.isEmpty {
            print("warning, found \(literals.duplicatedKeys.count) duplicated keys found on \(file), unique keys: \(literals.keys.count)")
            print("\n----------------")

            let sortedDuplicates = literals.duplicatedKeys
                .sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })

            print(sortedDuplicates.joined(separator: "\n"))
            print("---------------\n")
        } else {
            print("found \(literals.keys.count) on \(file)")
        }
    }
}
