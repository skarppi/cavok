//
//  ColorRamp.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 18.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import SwiftUI

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

    init(module: Module) {
        unit = module.unit

        let sorted = Array(module.legend).sorted(by: {$0.key < $1.key})
        let keys = sorted.map { (key, _) in Int32(key)! }
        titles = sorted.map { (_, value) in value }

        steps = keys.enumerated().map { (i, step) in
            let next = (i + 1) < keys.count ? keys[i + 1] : Int32.max
            return GridStep(lower: step, upper: next, fromHue: hues[i][0], toHue: hues[i][1])
        }
    }

    func color(for value: Int32, alpha: CGFloat = 1) -> Color {
        if let step = steps.reversed().first(where: { value >= $0.lower}) {
            // Point-Slope Equation of a Line: y - y1 = m(x - x1)
            let slope = CGFloat(step.toHue - step.fromHue) / CGFloat(step.upper - step.lower)
            let hue = slope * CGFloat(value - step.lower) + CGFloat(step.fromHue)

            return Color(hue: hue/360, saturation: 1, brightness: brightness, opacity: alpha)
        } else {
            return Color.black
        }
    }

    class func color(forMinutes minutes: Int, alpha: CGFloat = 1) -> Color {
        if minutes < 0 {
            return Color(hue: CGFloat(blue[0])/360, saturation: 1, brightness: brightness, opacity: alpha)
        } else if minutes <= 30 {
            return ColorRamp.color(for: .VISUAL, alpha: alpha)
        } else if minutes <= 90 {
            return ColorRamp.color(for: .MARGINAL, alpha: alpha)
        } else {
            return ColorRamp.color(for: .INSTRUMENT, alpha: alpha)
        }
    }

    class func color(for condition: WeatherConditions, alpha: CGFloat = 1) -> Color {
        switch condition {
        case .VISUAL:
            return Color(hue: 120/360, saturation: 1, brightness: brightness, opacity: alpha)
        case .MARGINAL:
            return Color(hue: CGFloat(orange[0])/360, saturation: 1, brightness: brightness, opacity: alpha)
        case .INSTRUMENT:
            return Color(hue: 0, saturation: 1, brightness: 0.61, opacity: alpha)
        default:
            return Color(hue: 0, saturation: 0, brightness: 0.1, opacity: alpha)
        }
    }
}
