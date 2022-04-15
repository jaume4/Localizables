// UpdateFolderCommand.swift
// Localizables

import ArgumentParser
import Foundation
import LocalizablesCore

struct UpdateFolderCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(commandName: "folder",
                                                    abstract: "Search and update the contents of a folder.")

    typealias File = (language: String, url: URL)

    @Argument(help: "Path to the localizable file to be updated", transform: URL.init(fileURLWithPath:))
    var destinationFolder: URL

    @Argument(help: "Path to the localizable file containing the updates", transform: URL.init(fileURLWithPath:))
    var updateFolder: URL

    @Option(name: .shortAndLong, help: "Base language")
    var baseLanguage = "en"

    mutating func run() async throws {
        // avoid error: reference to captured parameter 'self' in concurrently-executing code
        let destinationFolderURL = destinationFolder
        let updateFolderURL = updateFolder

        let destinationFiles = try await scan(folder: destinationFolderURL)
        let updateFiles = try await scan(folder: updateFolderURL)

        let filePairs = try match(destination: destinationFiles, update: updateFiles)

        let (successCount, failureCount) = await update(filePairs)

        if failureCount > 0 {
            throw "Failed to update \(failureCount) files, \(successCount) files updated successfully".red
        } else {
            print("Updated \(successCount) files successfully".green)
        }
    }

    /// Scans the URL attempting to find .strings files and extracting it's language from it's url
    /// Expects the URL to have ../es.lproj/XX.strings format
    func scan(folder: URL) async throws -> [File] {
        await Task {
            let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .nameKey]
            let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: Array(resourceKeys))!

            return enumerator
                .compactMap { $0 as? URL }
                .compactMap { fileURL in
                    guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                          let isDirectory = resourceValues.isDirectory,
                          !isDirectory,
                          let name = resourceValues.name,
                          name.hasSuffix(".strings")
                    else {
                        return nil
                    }

                    let pathComponents = fileURL.pathComponents

                    guard pathComponents.count >= 2 else {
                        return nil
                    }

                    // ../es.lproj/XX.strings
                    let language = pathComponents[pathComponents.count - 2]
                        .replacingOccurrences(of: ".lproj", with: "")

                    return (language, fileURL)
                }
        }.value
    }

    /// Matches the files to destination files with the update ones based on language
    func match(destination: [File], update: [File]) throws -> [(URL, URL)] {
        // TODO: support same-language region variants

        var matchedFiles: [(URL, URL)] = []

        let languages = extractLanguages(from: update)

        for file in destination {
            var language = file.language
            if language == "Base" {
                language = baseLanguage
            }

            guard let updateFileIndex = languages[language] else {
                throw "Language not found at \(file.url)"
            }

            let updateFile = update[updateFileIndex]
            matchedFiles.append((file.url, updateFile.url))
        }

        return matchedFiles
    }

    /// Extract the language the file path: ../ca-ES.lproj/xx.strings
    /// - Attention: Does not support same-language region variants
    /// - Parameter files: Found strings files
    /// - Returns: A dictionary containing the language as key and it's position on the files array as a value
    func extractLanguages(from files: [File]) -> [String: Int] {
        // TODO: support same-language region variants

        files.enumerated().reduce(into: [:]) { languages, arg in
            let (index, (language, _)) = arg

            let parsedLanguage: String

            let splitLang = language.split(separator: "-") // "ca-ES" -> "ca"
            if let prefixLanguage = splitLang.first {
                parsedLanguage = String(prefixLanguage)
            } else {
                parsedLanguage = language
            }

            languages[parsedLanguage] = index
        }
    }

    private func update(_ filePairs: [(URL, URL)]) async -> (Int, Int) {
        return await withTaskGroup(of: Bool.self) { group in
            filePairs.forEach { destinationURL, updateURL in
                group.addTask {
                    await Self.update(destinationURL: destinationURL, updateURL: updateURL)
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

    /// Tries to update the destination file with the values found on the update file
    static func update(destinationURL: URL, updateURL: URL) async -> Bool {
        var fileUpdater = UpdateFileCommand()
        fileUpdater.destinationFile = destinationURL
        fileUpdater.updatedFile = updateURL

        do {
            try await fileUpdater.run()
            return true
        } catch {
            var stdError = FileHandle.standardError
            print(String.separator, to: &stdError)
            print("Failed to update \(destinationURL)".red, to: &stdError)
            print(error, to: &stdError)
            return false
        }
    }
}
