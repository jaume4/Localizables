// UpdateFolderCommand.swift
// Localizables

import ArgumentParser
import Foundation
import LocalizablesCore

struct UpdateFolderCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(commandName: "folder",
                                                    abstract: "Search and update the contents of a folder.")

    typealias File = (language: String, url: URL)

    @Argument(help: "Path to the folder containing the .strings files to be updated", transform: URL.init(fileURLWithPath:))
    var destinationFolder: URL

    @Argument(help: "Path to the folder containing the .strings files to use as updates", transform: URL.init(fileURLWithPath:))
    var updateFolder: URL

    @Option(name: .shortAndLong, help: "Base language")
    var baseLanguage = "en"

    mutating func run() async throws {
        let updater = FolderScanner(destinationFolder: destinationFolder, updateFolder: updateFolder, baseLanguage: baseLanguage)

        let filePairs = try await updater.findMatches()

        let (successCount, failureCount) = await update(filePairs)

        if failureCount > 0 {
            throw "Failed to update \(failureCount) files, \(successCount) files updated successfully".red
        } else {
            print("Updated \(successCount) files successfully".green)
        }
    }

    private func update(_ filePairs: [FolderScanner.FilePair]) async -> (successCount: Int, failureCount: Int) {
        await withTaskGroup(of: Bool.self) { group in
            for (destinationURL, updateURL) in filePairs {
                group.addTask {
                    await update(destinationURL: destinationURL, updateURL: updateURL)
                }
            }

            var successCount = 0
            var failureCount = 0

            for await succeeded in group {
                succeeded ? (successCount += 1) : (failureCount += 1)
            }

            return (successCount, failureCount)
        }
    }

    func update(destinationURL: URL, updateURL: URL) async -> Bool {
        var fileUpdater = UpdateFileCommand(destinationFile: destinationURL, updateFile: updateURL)

        do {
            try await fileUpdater.run()
            return true
        } catch {
            await OutputSynchronizer.perform {
                var stdError = FileHandle.standardError
                print(String.separator, to: &stdError)
                print("Failed to update \(destinationURL)".red, to: &stdError)
                print(error, to: &stdError)
            }
            return false
        }
    }
}
