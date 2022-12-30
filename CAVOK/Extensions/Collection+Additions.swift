//
//  Collection+Additions.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 30.11.2021.
//

import Foundation

extension Collection where Indices.Iterator.Element == Index {

    subscript (safe index: Index?) -> Iterator.Element? {
        if let index = index, indices.contains(index) {
            return self[index]
        }
        return nil
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

extension Error {
    public var isCancelled: Bool {
        do {
            throw self
        } catch URLError.cancelled {
            return true
        } catch CocoaError.userCancelled {
            return true
        } catch {
        #if os(macOS) || os(iOS) || os(tvOS)
            let pair = { ($0.domain, $0.code) }(error as NSError)
            return ("SKErrorDomain", 2) == pair
        #else
            return false
        #endif
        }
    }
}
