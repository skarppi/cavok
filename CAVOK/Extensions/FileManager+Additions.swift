//
//  FileManager+Additions.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 6.2.2023.
//

import Foundation

let appGroup = "group.net.tusina.CAVOK"

extension FileManager {

    func cavokAppGroup() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }
}

extension UserDefaults {
    static var cavok: UserDefaults? {
        return UserDefaults(suiteName: appGroup)
    }

    static func store<T: Encodable>(_ object: T) {
        store(object, forKey: "\(T.self)")
    }

    private static func store<T: Encodable>(_ object: T, forKey: String) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            cavok?.set(data, forKey: forKey)
        } catch {
            print("Failed to write UserDefaults \(forKey): \(error)")
        }
    }

    static func read<T: Decodable>() -> T? {
        return read(forKey: "\(T.self)")
    }

    private static func read<T: Decodable>(forKey: String) -> T? {
        guard let data = cavok?.data(forKey: forKey) else { return nil }
        let decoder = JSONDecoder()
        do {
            let object = try decoder.decode(T.self, from: data)
            return object
        } catch {
            print("Failed to read UserDefaults \(forKey): \(error)")
            return nil
        }
    }
}
