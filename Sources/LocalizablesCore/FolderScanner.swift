// FolderScanner.swift
// Localizables

import Foundation

public struct FolderScanner {
    typealias File = (language: String, url: URL)
    public typealias FilePair = (source: URL, update: URL)

    let destinationFolder: URL
    let updateFolder: URL
    let baseLanguage: String

    public init(destinationFolder: URL, updateFolder: URL, baseLanguage: String) {
        self.destinationFolder = destinationFolder
        self.updateFolder = updateFolder
        self.baseLanguage = baseLanguage
    }

    /// Scans the given URLs attempting to find .strings files and extracting the language from it's path
    /// - Note: Expects the URL to have ../es.lproj/XX.strings format
    /// - Returns: Matched files
    public func findMatches() async throws -> [FilePair] {
        async let destinationFiles = scan(folder: destinationFolder)
        async let updateFiles = scan(folder: updateFolder)

        let filePairs = try match(destination: await destinationFiles, update: await updateFiles)

        return filePairs
    }

    func scan(folder: URL) async -> [File] {
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
    func match(destination: [File], update: [File]) throws -> [FilePair] {
        // TODO: support same-language region variants

        var matchedFiles: [FilePair] = []

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
}
