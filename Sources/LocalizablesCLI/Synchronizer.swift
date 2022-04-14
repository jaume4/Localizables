// Synchronizer.swift
// Localizables

import Foundation

actor Synchronizer {
    private static var sync = Synchronizer()
    private init() {}

    static func perform(_ action: () throws -> Void) async rethrows {
        try await sync.perform(action)
    }

    func perform(_ action: () throws -> Void) rethrows {
        try action()
    }
}
