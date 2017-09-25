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
        return modules().flatMap { module in
            module["name"] as? String
        }
    }
    
    class func loadModule(index: Int, delegate: MapDelegate) -> MapModule {
        let module = modules()[index]
        let className = module["class"] as! String
        
        let type = NSClassFromString("CAV_OK.\(className)") as! MapModule.Type
        return type.init(delegate: delegate)
    }
    
    class func configuration(module: AnyClass) -> [String: AnyObject]? {
        let moduleClassName = String(describing: module)
        
        if let module = modules().first(where: { $0["class"] as? String == moduleClassName }) {
            return module
        } else {
            return nil
        }
    }
    
    class func index(of module: AnyClass) -> Int? {
        let moduleClassName = String(describing: module)
        
        return modules().flatMap { module in
            module["class"] as? String
        }.index(of: moduleClassName)
    }
}
