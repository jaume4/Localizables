// UpdateFile.swift
// Localizables

import ArgumentParser
import Foundation
import LocalizablesCore

struct UpdateFile: AsyncParsableCommand {
    static var configuration = CommandConfiguration(commandName: "file",
                                                    abstract: "Update the contents of a file.")

    @Argument(help: "Path to the localizable file to be updated")
    var destinationFile: String

    @Argument(help: "Path to the localizable file containing the updates")
    var updatedFile: String

    mutating func run() async throws {
        let destinationURL = URL(string: destinationFile.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!.fileURL
        let updatedFileURL = URL(string: updatedFile.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!.fileURL

        #warning("fix no-context prints when using from folder update")
        print("Updating \(destinationURL.lastPathComponent) with \(updatedFileURL.lastPathComponent)")

        async let destinationLiterals = try LiteralsReader(url: destinationURL)
        async let updateLiterals = try LiteralsReader(url: updatedFileURL)

        var (destination, update) = (try await destinationLiterals, try await updateLiterals)

        printInfo(literals: destination, file: "destination")
        printInfo(literals: update, file: "updated")

        let missingKeys = destination.update(from: update)
            .sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })

        printMissing(keys: missingKeys)

        try destination.save()
    }

    func printMissing(keys: [String]) {
        guard !keys.isEmpty else {
            return
        }

        print("warning, missing keys found: \(keys.count)")
        print("\n----------------")
        print(keys.lazy.sorted().joined(separator: "\n"))
        print("---------------\n")
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
