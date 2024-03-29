//
//  Modules.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 27.01.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

struct Module: Hashable {
    var key: ModuleKey
    var title: String
    var unit: String
    var legend: [String: String]
    var reversed: Bool
}

enum ModuleKey: String {
    case ceiling, visibility, wind, temp, web
}

class Modules {
    static var available = load()

    static var ceiling: Module! {
        return available.first { module in
            module.key == ModuleKey.ceiling
        }
    }

    static var visibility: Module! {
        return available.first { module in
            module.key == ModuleKey.visibility
        }
    }

    private class func load() -> [Module] {
        guard let modules = UserDefaults.cavok?.array(forKey: "modules") as? [[String: AnyObject]]
            // issues in previews
                ?? UserDefaults.registerCavok()?.array(forKey: "modules") as? [[String: AnyObject]] else {
            return []
        }

        return modules.compactMap { module in
            if let key = ModuleKey(rawValue: module["key"] as? String ?? ""),
               let name = module["name"] as? String {
                return Module(key: key,
                              title: name,
                              unit: module["unit"] as? String ?? "",
                              legend: module["legend"] as? [String: String] ?? [:],
                              reversed: module["reversed"] as? Bool ?? false
                )
            } else {
                return nil
            }
        }
    }
}
