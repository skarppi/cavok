//
//  HeatMapCPU.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 06/10/2016.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class HeatMapCPU {

    var image: CGImage?

    let fadingDistance: Float

    let maxAlpha: Float = 0.55

    init(input: [HeatData], config: WeatherConfig, ramp: ColorRamp) {
        fadingDistance = Float(config.radius) / 2

        let bitmapData = UnsafeMutablePointer<UInt8>.allocate(capacity: config.width * config.height * 4)

        for y in 0 ... config.height - 1 {
            for x in 0 ... config.width - 1 {

                let i = config.width * (config.height - 1 - y) + x

                let interp = getInterpValue(x: x, y: y, input: input)

                let color = ramp.color(for: Int32(interp.val), alpha: CGFloat(interp.alpha))
                let comps = color.cgColor.components!
                let alpha = comps[3] * 255
                bitmapData[i*4 + 0] = UInt8(comps[0] * alpha)
                bitmapData[i*4 + 1] = UInt8(comps[1] * alpha)
                bitmapData[i*4 + 2] = UInt8(comps[2] * alpha)
                bitmapData[i*4 + 3] = UInt8(alpha)
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        let context = CGContext(data: bitmapData,
                                width: config.width,
                                height: config.height,
                                bitsPerComponent: 8,
                                bytesPerRow: config.width * 4,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue)

        image = context?.makeImage()

        free(bitmapData)
    }

    func render() -> CGImage? {
        // DebugTileSource.save(MaplyTileID(x: 0, y: 0, level: 0), image: image!)
        return image
    }

    // Inverse Distance Weighted interpolation using Shepard's method
    // https://github.com/tomschofield/ofxHeatMap/blob/master/ofxHeatMap/src/ofxHeatMap.cpp

    private func getAllDistancesFromPoint(x: Int32, y: Int32, input: [HeatData]) -> [Float] {
        return input.map { data -> Float in
            return sqrt(pow(Float(x - data.x), 2) + pow(Float(y - data.y), 2))
        }
    }

    func getInterpValue(x: Int, y: Int, input: [HeatData]) -> (val: Float, alpha: Float) {
        guard !input.isEmpty else {
            return (0, 0)
        }

        let distances = getAllDistancesFromPoint(x: Int32(x), y: Int32(y), input: input)
        let minDistance = distances.min()!
        let maxDistance = distances.max()!

        var sum: Float = 0
        var second: Float = 0
        for distance in distances {
            sum += distance
            second += pow(((maxDistance - distance)/( maxDistance * distance)), 2)
        }
        if second == 0 {
            return (0, 0)
        }

        var res: Float = 0
        for current in input.enumerated() {
            let thisDistance = distances[current.offset]

            if thisDistance == 0 {
                res += Float(current.element.value)
            } else {
                let first = pow(((maxDistance - thisDistance)/( maxDistance * thisDistance)), 2)
                res += Float(current.element.value) * first / second
            }
        }

        if minDistance >= fadingDistance {
            return (res, min(maxAlpha, max(0, maxAlpha - maxAlpha / fadingDistance * (minDistance - fadingDistance))))
        }
        return (res, maxAlpha)
    }
}
