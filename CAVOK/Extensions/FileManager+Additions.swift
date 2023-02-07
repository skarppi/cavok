//
//  FileManager+Additions.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 6.2.2023.
//

import Foundation

extension FileManager {

    func cavokAppGroup() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.net.tusina.CAVOK")
    }
}

extension UserDefaults {
    static var cavok: UserDefaults? {
        return UserDefaults(suiteName: "group.net.tusina.CAVOK")
    }
}
