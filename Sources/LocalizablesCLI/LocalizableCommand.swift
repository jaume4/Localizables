// LocalizableCommand.swift
// Localizables

import ArgumentParser
import Foundation
import LocalizablesCore

@main
struct LocalizableCommand: ParsableCommand {
    @Argument(help: "Path to the origin localizable file")
    var originFile: String

    @Argument(help: "Path to the target localizable file to update")
    var destinationFile: String

    mutating func run() throws {
        let originURL = URL(string: originFile.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!.fileURL
        let destinationURL = URL(string: destinationFile.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!.fileURL

        var parser = LiteralsUpdater(originURL: originURL, destinationURL: destinationURL)

        try parser.run()
        try parser.save()
    }
}
