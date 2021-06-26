//
//  Modules.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 27.01.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class Modules {

    private class func modules() -> [[String: AnyObject]] {
        if let modules = UserDefaults.standard.array(forKey: "modules") as? [[String: AnyObject]] {
            return modules
        } else {
            return []
        }
    }

    class func availableTitles() -> [String] {
        return modules().compactMap { module in
            module["name"] as? String
        }
    }

    class func loadModule(title: String, delegate: MapApi) -> MapModule {
        if let module = modules().first(where: { $0["name"] as? String == title}),
           let className = module["class"] as? String,
           let type = NSClassFromString("CAV_OK.\(className)") as? MapModule.Type {
            return type.init(delegate: delegate)
        } else {
            preconditionFailure("config error")
        }
    }

    class func configuration(module: AnyClass) -> [String: AnyObject]? {
        let moduleClassName = String(describing: module)

        if let module = modules().first(where: { $0["class"] as? String == moduleClassName }) {
            return module
        } else {
            return nil
        }
    }

    class func title(of moduleType: AnyClass) -> String? {
        if let module = Modules.configuration(module: moduleType) {
            return module["name"] as? String
        } else {
            return nil
        }
    }

}
