//
//  ColorRamp.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 18.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

struct GridStep {
    var lower: Int32
    var upper: Int32
    var fromHue: Int32
    var toHue: Int32
    
    func int4() -> [Int32] {
        return [lower, upper, fromHue, toHue]
    }
}

struct GridSteps {
    var purple: GridStep
    var red: GridStep
    var orange: GridStep
    var yellow: GridStep
    var green: GridStep
    var blue: GridStep
    
    init(purple: Int32, red: Int32, orange: Int32, yellow: Int32, green: Int32, blue: Int32) {
        self.purple = GridStep(lower: purple, upper: red, fromHue: 300, toHue: 359)
        self.red = GridStep(lower: red, upper: orange, fromHue: 0, toHue: 45)
        self.orange = GridStep(lower: orange, upper: yellow, fromHue: 45, toHue: 60)
        self.yellow = GridStep(lower: yellow, upper: green, fromHue: 60, toHue: 75)
        self.green = GridStep(lower: green, upper: blue, fromHue: 75, toHue: 190)
        self.blue = GridStep(lower: blue, upper: blue * 10, fromHue: 190, toHue: 200)
    }
    
    func stepFor(value: Int32) -> GridStep? {
        if(value >= blue.lower) {
            return blue
        } else if(value >= green.lower) {
            return green
        } else if(value >= yellow.lower) {
            return yellow
        } else if(value >= orange.lower) {
            return orange
        } else if(value >= red.lower) {
            return red
        } else if(value >= purple.lower) {
            return purple
        } else {
            return nil
        }

    }
}

class ColorRamp {
    let unit: String
    
    let steps: GridSteps
    
    init(module: WeatherModule.Type) {
        let moduleClassName = String(describing: module)
        
        let modules = UserDefaults.standard.array(forKey: "modules") as! [[String:AnyObject]]
        
        if let module = modules.first(where: { $0["class"] as? String == moduleClassName }),
            let steps = module["steps"] as? [String:String] {
            
            self.unit = module["unit"] as? String ?? ""
            
            let k = Array(steps.keys).sorted(by: {$0 < $1}).map { key in Int32(key)! }
            self.steps = GridSteps(purple: k[0], red: k[1], orange: k[2], yellow: k[3], green: k[4], blue: k[5])
        } else {
            self.steps = GridSteps(purple:0, red:0, orange:0, yellow:0, green:0, blue: 0)
            self.unit = ""
        }
    }
    
    func color(for value: Int, alpha: CGFloat = 1) -> CGColor {
        let value32 = Int32(value)
        let brightness = CGFloat(0.81)
        
        if let step = steps.stepFor(value: value32) {
            // Point-Slope Equation of a Line: y - y1 = m(x - x1)
            let slope = CGFloat(step.toHue - step.fromHue) / CGFloat(step.upper - step.lower)
            let hue = slope * CGFloat(value32 - step.lower) + CGFloat(step.fromHue)
            
            return UIColor(hue:hue/360, saturation:1, brightness:brightness, alpha:alpha).cgColor
        } else {
            return UIColor.black.cgColor
        }
    }
    
    class func color(for date: Date, alpha: CGFloat = 1) -> UIColor {
        let minutes = Int(date.timeIntervalSinceNow.negated() / 60)
        return ColorRamp.color(forMinutes: minutes, alpha: alpha)
    }
    
    class func color(forMinutes minutes: Int, alpha: CGFloat = 1) -> UIColor {
        if (minutes < 0) {
            return UIColor(hue:190/360, saturation:1, brightness:0.81, alpha:alpha)
        } else if(minutes <= 30) {
            return ColorRamp.color(for: .VFR, alpha: alpha)
        } else if(minutes <= 90) {
            return ColorRamp.color(for: .MVFR, alpha: alpha)
        } else {
            return ColorRamp.color(for: .IFR, alpha: alpha)
        }
    }
    
    class func color(for condition: WeatherConditions, alpha: CGFloat = 1) -> UIColor {
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
