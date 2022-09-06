// Extensions.swift
// Localizables

import Foundation

extension String {
    var `default`: String { "\u{001B}[39m\(self)" }
    var red: String { "\u{001B}[31m\(self)\u{001B}[0m" }
    var green: String { "\u{001B}[32m\(self)\u{001B}[0m" }
    var yellow: String { "\u{001B}[33m\(self)\u{001B}[0m" }

    static let separator = "\n" + String(repeating: "-", count: 32)
}
