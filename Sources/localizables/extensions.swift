// extensions.swift
// Localizables

import Foundation

extension URL {
    var fileURL: URL {
        if scheme == nil {
            return URL(string: "file://" + absoluteString)!
        } else {
            return self
        }
    }

    var terminalPath: String {
        absoluteString.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " ")
    }
}
