//
//  AirspaceAttributes.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 25.02.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class AirspaceAttributes {
    let coordinate: MaplyCoordinate
    
    let name: String
    
    let upperLimit: Int?
    
    let lowerLimit: Int?
    
    let description: String
    
    var color:UIColor {
        get {
            let alpha = CGFloat(0.8)
            
            guard let lowerLimit = lowerLimit else {
                return UIColor(hue:0, saturation:0, brightness:0.1, alpha:alpha)
            }
            
            switch lowerLimit {
            case let l where l > 0:
                return UIColor(hue:120/360, saturation:1, brightness:0.81, alpha:alpha)
            case 0 where name.isMatch("EFP\\d+"):
                return UIColor(hue:0, saturation:1, brightness:0.61, alpha:alpha)
            default:
                return UIColor(hue:45/360, saturation:1, brightness:0.81, alpha:alpha)
            }
        }
    }
    
    class func parseLimit(str: String) -> Int? {
        if str == "SFC" {
            return 0
        } else if str.hasPrefix("FL") {
            return Int(str.replace("FL", with: "").trim()).map { $0 * 1000 }
        } else {
            return Int(str.replace("FT MSL", with: "").trim())
        }
    }
    
    init(coordinate: MaplyCoordinate, attributes: [String: AnyObject]) {
        self.coordinate = coordinate
        
        self.name = attributes["designation"] as! String
        
        let upperLimitStr = attributes["upperVerticalLimit"] as? String
        let lowerLimitStr = attributes["lowerVerticalLimit"] as? String
        
        self.upperLimit = upperLimitStr.flatMap(AirspaceAttributes.parseLimit)
        self.lowerLimit = lowerLimitStr.flatMap(AirspaceAttributes.parseLimit)
        
        self.description = {
            let u = upperLimitStr.map { "Upper limit: \($0)\n" } ?? ""
            let l = lowerLimitStr.map { "Lower limit: \($0)" } ?? ""
            return u + l
        }()
    }
}
