// LocalizableCommand.swift
// Localizables

import ArgumentParser
import Foundation
import LocalizablesCore

@main
struct LocalizableCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(abstract: "A utility for performing updates on localizable files.",
                                                    subcommands: [UpdateFile.self, UpdateFiles.self])
}
