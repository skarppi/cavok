//
//  Modules.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 27.01.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class Modules {
    
    func availableTitles() -> [String] {
        if let modules = UserDefaults.standard.array(forKey: "modules") as? [[String: AnyObject]] {
            return modules.flatMap { $0["name"] as? String }
        } else {
            return []
        }
    }
    
    func loadModule(index: Int, delegate: MapDelegate) -> MapModule {
        let modules = UserDefaults.standard.array(forKey: "modules") as! [[String:AnyObject]]
        
        let module = modules[index]
        let className = module["class"] as! String
        
        let type = NSClassFromString("CAVOK.\(className)") as! MapModule.Type
        return type.init(delegate: delegate)
    }
}
