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

let purple: [Int32] = [300, 359]
let red: [Int32] = [0, 45]
let orange: [Int32] = [45, 60]
let yellow: [Int32] = [60, 75]
let green: [Int32] = [75, 190]
let blue: [Int32] = [190, 200]

let hues: [[Int32]] = [ purple, red, orange, yellow, green, blue]

let brightness: CGFloat = 0.81

class ColorRamp {
    let unit: String
    
    let steps: [GridStep]
    
    let titles: [String]
    
    init(module: WeatherModule.Type) {
        let moduleClassName = String(describing: module)
        
        let modules = UserDefaults.standard.array(forKey: "modules") as! [[String:AnyObject]]
        
        if let module = modules.first(where: { $0["class"] as? String == moduleClassName }),
            let steps = module["steps"] as? [String:String] {
            
            self.unit = module["unit"] as? String ?? ""
            
            let sorted = Array(steps).sorted(by: {$0.key < $1.key})
            let keys = sorted.map { (key, _) in Int32(key)! }
            titles = sorted.map { (_, value) in value }
            
            self.steps = keys.enumerated().map { (i, step) in
                let next = (i + 1) < keys.count ? keys[i + 1] : Int32.max
                return GridStep(lower: step, upper: next, fromHue: hues[i][0], toHue: hues[i][1])
            }
        } else {
            self.unit = ""
            self.steps = []
            self.titles = []
        }
    }
    
    func legend() -> Legend {
        return Legend(unit: unit, gradient: steps.map { step in color(for: Int(step.lower))}, titles: titles)
    }
    
    func color(for value: Int, alpha: CGFloat = 1) -> CGColor {
        let value32 = Int32(value)
        
        if let step = steps.reversed().first(where: { value32 >= $0.lower}) {
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
            return UIColor(hue: CGFloat(blue[0])/360, saturation:1, brightness:brightness, alpha:alpha)
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
            return UIColor(hue:120/360, saturation:1, brightness:brightness, alpha:alpha)
        case .MVFR:
            return UIColor(hue:CGFloat(orange[0])/360, saturation:1, brightness:brightness, alpha:alpha)
        case .IFR:
            return UIColor(hue:0, saturation:1, brightness:0.61, alpha:alpha)
        default:
            return UIColor(hue:0, saturation:0, brightness:0.1, alpha:alpha)
        }
    }
}
