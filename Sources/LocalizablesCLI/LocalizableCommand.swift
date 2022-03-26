// LocalizableCommand.swift
// Localizables

import ArgumentParser
import Foundation
import LocalizablesCore

@main
struct LocalizableCommand: ParsableCommand {
    @Argument(help: "Path to the localizable file to be updated")
    var destinationFile: String

    @Argument(help: "Path to the localizable file containing the updates")
    var updatedFile: String

    mutating func run() throws {
        let destinationURL = URL(string: destinationFile.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!.fileURL
        let updatedFileURL = URL(string: updatedFile.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!.fileURL

        var destinationLiterals = try LiteralsReader(url: destinationURL)
        printInfo(literals: destinationLiterals, file: "destination")

        let updateLiterals = try LiteralsReader(url: updatedFileURL)
        printInfo(literals: updateLiterals, file: "updated")

        let missingKeys = destinationLiterals.update(from: updateLiterals)
            .sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })

        if !missingKeys.isEmpty {
            print("warning, missing keys found: \(missingKeys.count)")
            print("\n----------------")
            print(missingKeys.lazy.sorted().joined(separator: "\n"))
            print("---------------\n")
        }

        try destinationLiterals.save()
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
