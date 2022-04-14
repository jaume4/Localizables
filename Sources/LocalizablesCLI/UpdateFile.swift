// UpdateFile.swift
// Localizables

import ArgumentParser
import Foundation
import LocalizablesCore

struct UpdateFile: AsyncParsableCommand {
    static var configuration = CommandConfiguration(commandName: "file",
                                                    abstract: "Update the contents of a file.")

    @Argument(help: "Path to the localizable file to be updated", transform: URL.init(fileURLWithPath:))
    var destinationFile: URL

    @Argument(help: "Path to the localizable file containing the updates", transform: URL.init(fileURLWithPath:))
    var updatedFile: URL

    mutating func run() async throws {
        // async command does not support do capture self
        let destinationFile = destinationFile
        let updatedFile = updatedFile

        async let destinationLiterals = try LiteralsReader(url: destinationFile)
        async let updateLiterals = try LiteralsReader(url: updatedFile)

        var (destination, update) = (try await destinationLiterals, try await updateLiterals)

        let missingKeys = destination.update(from: update)
            .sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })

        try destination.save()

        await Synchronizer.perform {
            print("\n" + String(repeating: "-", count: 32))
            print("Updated \(destinationFile) with \(updatedFile)")
            printInfo(literals: destination, file: "destination")
            printInfo(literals: update, file: "updated")
            printMissing(keys: missingKeys)
        }
    }

    func printMissing(keys: [String]) {
        guard !keys.isEmpty else {
            return
        }

        print("\n\nwarning found \(keys.count) missing keys ")
        keys.lazy.sorted().forEach {
            print("  ", $0)
        }
    }

    func printInfo(literals: LiteralsReader, file: String) {
        if !literals.duplicatedKeys.isEmpty {
            print("\n\nwarning found \(literals.duplicatedKeys.count) duplicated keys on \(file), unique keys count: \(literals.keys.count)")

            let sortedDuplicates = literals.duplicatedKeys
                .sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })

            sortedDuplicates.forEach {
                print("  ", $0)
            }
        }
    }
}
