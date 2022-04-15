// OutputSynchronizer.swift
// Localizables

import Foundation

/// Used to sync output printing
actor OutputSynchronizer {
    private static var sync = OutputSynchronizer()
    private init() {}

    static func perform(_ action: () throws -> Void) async rethrows {
        try await sync.perform(action)
    }

    func perform(_ action: () throws -> Void) rethrows {
        try action()
    }
}
