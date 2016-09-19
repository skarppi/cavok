//
//  ColorRamp.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 18.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

fileprivate struct GridSteps {
    var purple: Int
    var red: Int
    var orange: Int
    var yellow: Int
    var green: Int
    var blue: Int
}

class ColorRamp {
    let unit: String
    
    private let steps: GridSteps
    
    init(module: MapModule) {
        let moduleClassName = String(describing: type(of: module))
        
        let modules = UserDefaults.standard.array(forKey: "modules") as! [[String:AnyObject]]
        
        if let module = modules.first(where: { $0["class"] as? String == moduleClassName }),
            let steps = module["steps"] as? [String:String] {
            
            self.unit = module["unit"] as? String ?? ""
            
            let k = Array(steps.keys).sorted(by: {$0 < $1}).map { key in Int(key)! }
            self.steps = GridSteps(purple: k[0], red: k[1], orange: k[2], yellow: k[3], green: k[4], blue: k[5])
        } else {
            self.steps = GridSteps(purple: 0,red: 0,orange: 0,yellow: 0,green: 0,blue: 0)
            self.unit = ""
        }
    }
    
    func color(forValue value: Int, alpha: CGFloat) -> CGColor {
        // Point-Slope Equation of a Line: y - y1 = m(x - x1)
        func HueValue (_ x: Int, xFrom: Int, xTo: Int, hueFrom: CGFloat, hueTo: CGFloat) -> CGFloat {
            let slope = (hueTo - hueFrom) / CGFloat(xTo - xFrom)
            return (slope * CGFloat(x - xFrom) + hueFrom) / 360
        }
        
        let hue: CGFloat
        let brightness = CGFloat(0.81)
        
        if(value >= steps.blue) {
            hue = HueValue(value, xFrom: steps.blue, xTo: steps.blue * 2, hueFrom: 190, hueTo: 200)
            //brightness = HueValue(value, xFrom: steps.blue, xTo: steps.blue * 2, hueFrom: 0.81*360, hueTo: 360)
        } else if(value >= steps.green) {
            hue = HueValue(value, xFrom: steps.green, xTo: steps.blue, hueFrom: 75, hueTo: 190) // 75, 120
        } else if(value >= steps.yellow) {
            hue = HueValue(value, xFrom: steps.yellow, xTo: steps.green, hueFrom: 60, hueTo: 75)
        } else if(value >= steps.orange) {
            hue = HueValue(value, xFrom: steps.orange, xTo: steps.yellow, hueFrom: 45, hueTo: 60)
        } else if(value >= steps.red) {
            hue = HueValue(value, xFrom: steps.red, xTo: steps.orange, hueFrom: 0, hueTo: 45)
            //brightness = HueValue(value, steps.red, steps.orange, .61, .81)
        } else if(value >= steps.purple) {
            hue = HueValue(value, xFrom: steps.purple, xTo: steps.red, hueFrom: 300, hueTo: 359)
        } else {
            hue = alpha
        }
        
        return UIColor(hue:hue, saturation:1, brightness:brightness, alpha:alpha).cgColor
    }
    
    class func color(forCondition condition: WeatherConditions, alpha: CGFloat = 0.8) -> UIColor {
        switch condition {
        case .VFR:
            return UIColor(hue:120/360, saturation:1, brightness:0.81, alpha:alpha)
        case .MVFR:
            return UIColor(hue:45/360, saturation:1, brightness:0.81, alpha:alpha)
        case .IFR:
            return UIColor(hue:0, saturation:1, brightness:0.61, alpha:alpha)
        default:
            return UIColor(hue:0, saturation:0, brightness:0.1, alpha:alpha)
        }
    }
}
