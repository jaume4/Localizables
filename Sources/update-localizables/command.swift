// command.swift
// Localizables

import ArgumentParser
import Foundation

@main
struct Localizables: ParsableCommand {
    @Argument(help: "Path to the origin localizable file")
    var originFile: String

    @Argument(help: "Path to the target localizable file to update")
    var destinationFile: String

    mutating func run() throws {
        let originURL = URL(string: originFile.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!.fileURL
        let destinationURL = URL(string: destinationFile.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!.fileURL

        print("reading destination file")
        let destinationString = try String(contentsOf: destinationURL)
        let destinationKeys = try LiteralsParser.parse(from: destinationString)

        print("found \(destinationKeys.count) keys on destination file")

        var keys: Set<String> = Set(minimumCapacity: destinationKeys.count)

        do {
            let duplicatedKeys = destinationKeys
                .map(\.key)
                .filter { !keys.insert($0).inserted }

            if !duplicatedKeys.isEmpty {
                print("warning, duplicated keys found, unique keys: \(keys.count), duplicated: \(duplicatedKeys.count)")
                print("\n----------------")
                print(duplicatedKeys.joined(separator: "\n"))
                print("---------------\n")
            }
        }

        print("reading origin file")
        let originString = try String(contentsOf: originURL)
        let originValues = try LiteralsParser.parse(from: originString)

        print("found \(originValues.count) keys on origin file")

        var foundKeys: Set<String> = []

        var destinationValues: [(key: String, value: String)] = []

        for (key, value) in originValues {
            if keys.contains(key), foundKeys.insert(key).inserted {
                destinationValues.append((key, value))
            }
        }

        let notFoundKeys = keys.subtracting(foundKeys)

        if !notFoundKeys.isEmpty {
            print("warning, missing keys found: \(notFoundKeys.count)")
            print("\n----------------")
            print(notFoundKeys.lazy.joined(separator: "\n"))
            print("---------------\n")

            for (key, value) in destinationKeys {
                if foundKeys.insert(key).inserted {
                    destinationValues.append((key, value))
                }
            }

        } else {
            print("no missing keys!")
        }

        destinationValues.sort(by: { $0.key.caseInsensitiveCompare($1.key) == .orderedAscending })

        try "".write(to: destinationURL, atomically: true, encoding: .utf8) // reset file
        let handle = try FileHandle(forWritingTo: destinationURL)

        for (key, value) in destinationValues {
            let string = "\"\(key)\" = \"\(value)\";\n"
            if #available(macOS 10.15.4, *) {
                try handle.write(contentsOf: Data(string.utf8))
            } else {
                handle.write(Data(string.utf8))
            }
        }

        if #available(macOS 10.15, *) {
            try handle.close()
        } else {
            handle.closeFile()
        }
    }
}
