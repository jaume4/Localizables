// UpdateLocalizables.swift
// Localizables

import ArgumentParser
import Foundation
import LocalizablesCore

@main
struct UpdateLocalizables: AsyncParsableCommand {
    static var configuration = CommandConfiguration(abstract: "A utility for performing updates on localizable files.",
                                                    subcommands: [UpdateFileCommand.self, UpdateFolderCommand.self])
}
