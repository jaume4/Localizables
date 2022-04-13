// UpdateFiles.swift
// Localizables

import ArgumentParser
import Foundation
import LocalizablesCore

struct UpdateFiles: AsyncParsableCommand {
    static var configuration = CommandConfiguration(commandName: "folder",
                                                    abstract: "Search and update the contents of a folder.")

    typealias File = (language: String, url: URL)

    @Argument(help: "Path to the localizable file to be updated")
    var destinationFolder: String

    @Argument(help: "Path to the localizable file containing the updates")
    var updateFolder: String

    @Option(name: .shortAndLong, help: "Base language")
    var baseLanguage = "en"

    mutating func run() async throws {
        let destinationFolderURL = URL(string: destinationFolder.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!.fileURL
        let updateFolderURL = URL(string: updateFolder.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!.fileURL

        let destinationFiles = try await scan(folder: destinationFolderURL)
        let updateFiles = try await scan(folder: updateFolderURL)

        let filePairs = try match(destination: destinationFiles, update: updateFiles)

        await withTaskGroup(of: Void.self) { group in
            filePairs.forEach { destinationURL, updateURL in
                group.addTask {
                    await Self.update(destinationURL: destinationURL, updateURL: updateURL)
                }
            }
        }
    }

    func scan(folder: URL) async throws -> [File] {
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
    }

    func match(destination: [File], update: [File]) throws -> [(URL, URL)] {
        var update = update
        var matchedFiles: [(URL, URL)] = []

        for file in destination {
            var language = file.language // TODO: support same-language region variants
            if language == "Base" {
                language = baseLanguage
            }

            guard let updateFileIndex = update.firstIndex(where: { $0.language.hasPrefix(language) }) else {
                throw "Language \(language) not found"
            }

            let updateFile = update.remove(at: updateFileIndex)
            matchedFiles.append((file.url, updateFile.url))
        }

        return matchedFiles
    }

    static func update(destinationURL: URL, updateURL: URL) async {
        var fileUpdater = UpdateFile()
        fileUpdater.destinationFile = destinationURL.absoluteString
        fileUpdater.updatedFile = updateURL.absoluteString

        do {
            try await fileUpdater.run()
        } catch {
            print("Failed to update \(destinationURL): \(error.localizedDescription)")
        }
    }
}
