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

        let originString = try String(contentsOf: originURL)

        let destinationString = try String(contentsOf: destinationURL)

        print("reading destination file")
        let targetKeys = try LiteralsParser.parse(from: destinationString)
        print("found \(targetKeys.count) keys on destination file")

        print("reading origin file")
        let originValues = try LiteralsParser.parse(from: originString)
        print("found \(originValues.count) keys on origin file")

        let keys = Set(targetKeys.map(\.key))
        var foundKeys: Set<String> = []

        var destinationValues: [(key: String, value: String)] = []

        for (key, value) in originValues {
            if keys.contains(key), foundKeys.insert(key).inserted {
                destinationValues.append((key, value))
            }
        }

        let notFoundKeys = keys.subtracting(foundKeys)

        if !notFoundKeys.isEmpty {
            print("missing keys\n----------------")
            print(notFoundKeys.joined(separator: "\n"))
            print("---------------")

            for (key, value) in targetKeys {
                if foundKeys.insert(key).inserted {
                    destinationValues.append((key, value))
                }
            }

        } else {
            print("no missing keys!")
        }

        destinationValues.sort(by: { $0.key < $1.key })

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
