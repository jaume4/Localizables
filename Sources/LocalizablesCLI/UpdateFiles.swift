// UpdateFiles.swift
// Localizables

import ArgumentParser
import Foundation
import LocalizablesCore

struct UpdateFiles: AsyncParsableCommand {
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
        let destinationFolderURL = destinationFolder
        let updateFolderURL = updateFolder

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
                throw "Language \(language) not found"
            }

            let updateFile = update[updateFileIndex]
            matchedFiles.append((file.url, updateFile.url))
        }

        return matchedFiles
    }

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

    static func update(destinationURL: URL, updateURL: URL) async {
        var fileUpdater = UpdateFile()
        fileUpdater.destinationFile = destinationURL
        fileUpdater.updatedFile = updateURL

        do {
            try await fileUpdater.run()
        } catch {
            print("Failed to update \(destinationURL): \(error.localizedDescription)")
        }
    }
}
