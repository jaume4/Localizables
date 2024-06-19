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

        var (destination, update) = try await (destinationFile, updateFile)

        destination.update(with: update)

        let missingKeys = destination.missingKeys

        try destination.save()

        await OutputSynchronizer.perform {
            print(String.separator)
            print("Updated \(destinationURL) with \(updateURL)".green)
            printMissing(keys: missingKeys)
        }
    }

    func printMissing(keys: [String]) {
        guard !keys.isEmpty else {
            return
        }

        var stdError = FileHandle.standardError

        print("\nwarning found \(keys.count) missing keys ".yellow, to: &stdError)
        for key in keys.lazy.sorted() {
            print("  ", key, to: &stdError)
        }
    }
}
