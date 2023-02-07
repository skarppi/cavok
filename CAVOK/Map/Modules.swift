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
}

enum ModuleKey: String {
    case ceiling, visibility, temp, web
}

class Modules {
    static var available = load()

    private class func load() -> [Module] {
        if let modules = UserDefaults.cavok?.array(forKey: "modules") as? [[String: AnyObject]] {
            return modules.compactMap { module in
                if let key = ModuleKey(rawValue: module["key"] as? String ?? ""),
                   let name = module["name"] as? String {
                    return Module(key: key,
                                  title: name,
                                  unit: module["unit"] as? String ?? "",
                                  legend: module["legend"] as? [String: String] ?? [:])
                } else {
                    return nil
                }
            }
        } else {
            return []
        }
    }
}
