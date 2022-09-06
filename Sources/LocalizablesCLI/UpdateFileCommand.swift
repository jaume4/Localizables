// UpdateFileCommand.swift
// Localizables

import ArgumentParser
import Foundation
import LocalizablesCore

struct UpdateFileCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(commandName: "file",
                                                    abstract: "Update the contents of a file.")

    @Argument(help: "Path to the localizable file to be updated", transform: URL.init(fileURLWithPath:))
    var destinationFile: URL

    @Argument(help: "Path to the localizable file containing the updates", transform: URL.init(fileURLWithPath:))
    var updatedFile: URL

    init() {}

    init(destinationFile: URL, updateFile: URL) {
        self.destinationFile = destinationFile
        updatedFile = updateFile
    }

    mutating func run() async throws {
        // avoid error: reference to captured parameter 'self' in concurrently-executing code
        let destinationURL = destinationFile
        let updateURL = updatedFile

        async let destinationFile = try LiteralsFile(url: destinationURL)
        async let updateFile = try LiteralsFile(url: updateURL)

        var (destination, update) = (try await destinationFile, try await updateFile)

        destination.update(with: update)

        let missingKeys = destination.missingKeys

        try destination.save()

        await OutputSynchronizer.perform {
            print(String.separator)
            print("Updated \(destinationURL) with \(updateURL)".green)
            printInfo(file: destination, name: "destination")
            printInfo(file: update, name: "updated")
            printMissing(keys: missingKeys)
        }
    }

    func printMissing(keys: [String]) {
        guard !keys.isEmpty else {
            return
        }

        var stdError = FileHandle.standardError

        print("\nwarning found \(keys.count) missing keys ".yellow, to: &stdError)
        keys.lazy.sorted().forEach {
            print("  ", $0, to: &stdError)
        }
    }

    func printInfo(file: LiteralsFile, name: String) {
        guard !file.duplicatedKeys.isEmpty else {
            return
        }

        var stdError = FileHandle.standardError

        print("\nwarning found \(file.duplicatedKeys.count) duplicated keys on \(name), unique keys count: \(file.keys.count)".yellow, to: &stdError)

        let sortedDuplicates = file.duplicatedKeys
            .sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })

        sortedDuplicates.forEach {
            print("  ", $0, to: &stdError)
        }
    }
}
