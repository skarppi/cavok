//
//  HeatMap.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 12.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import RealmSwift

class HeatMap {
    
    let observations: [Observation]
    
    let ramp: ColorRamp
    
    let config: WeatherConfig
    
    let frame: Int
    
    let input: [HeatData]
    
    var output: CGImage?
    
    typealias HeatData = (Int, MaplyCoordinate)
    
    init(observations: [Observation], config: WeatherConfig, observationValue: (Observation) -> Int?, ramp: ColorRamp, frame: Int) {
        
        self.observations = observations
        
        self.config = config
        
        self.ramp = ramp
        
        self.frame = frame
        
        self.input = observations.flatMap { obs in
            let coord = config.coordSystem.geo(toLocal: obs.station!.coordinate())
            
            if let intValue = observationValue(obs) {
                return (intValue, coord)
            } else {
                return nil
            }
        }
    }
    
    deinit {
        NSLog("Canceling heatmap")
    }
    
    typealias RawData = (value: UnsafeMutablePointer<Int>, alpha: UnsafeMutablePointer<CGFloat>)
    
    func generateOutput() {
        timer("hazard frame \(self.frame)") {
            let raw = self.calculateObservations()
            
            let bitmapData = self.calculateBitmatData(raw)
            free(raw.value)
            free(raw.alpha)
            
            self.output = self.renderImage(bitmapData)
            free(bitmapData)
        }
    }
    
    private func calculateObservations() -> RawData {
        
        let values = UnsafeMutablePointer<Int>.allocate(capacity: config.width * config.height)
        let alphas = UnsafeMutablePointer<CGFloat>.allocate(capacity: config.width * config.height)
        
        // how fast distance lowers alpha channel
        let pivot = CGFloat(-config.radius/2)
        // alpha is zero when distance > radius
        let zeroDistance = exp(CGFloat(config.radius)/pivot)
        
        for (value, coordinate) in input {
            let centerX = Int(round(coordToPixelsX(coordinate.x) - 0.5))
            let centerY = Int(round(coordToPixelsY(coordinate.y) - 0.5))
            
            for y in max(0, centerY - config.radius) ... min(config.height - 1, centerY + config.radius) {
                for x in max(0, centerX - config.radius) ... min(config.width - 1, centerX + config.radius) {
                    let yDiff = Float(y - centerY)
                    let xDiff = Float(x - centerX)
                    
                    let distance = sqrtf(yDiff*yDiff + xDiff*xDiff)
                    
                    let alpha: CGFloat
                    if (Int(distance) >= config.radius) {
                        continue
                    } else {
                        alpha = exp(CGFloat(distance)/pivot) - zeroDistance
                    }
                    
                    let index = config.width * (config.height - 1 - y) + x
                    if(values[index] > 0 && alphas[index] > 0) {
                        let oldAlpha = alphas[index]
                        
                        if abs(oldAlpha - alpha) < 0.05 && alpha < 0.5 {
                            let oldValue = CGFloat(values[index])
                            let totalValue = oldAlpha * oldValue + alpha * CGFloat(value)
                            let totalDistance = oldAlpha + alpha
                            values[index] = Int(totalValue / totalDistance)
                        } else if alpha > oldAlpha {
                            values[index] = value
                            alphas[index] = alpha
                        }
                        
                        assert(!alphas[index].isNaN)
                    } else {
                        values[index] = value
                        alphas[index] = alpha
                        
                        assert(!alphas[index].isNaN)
                    }
                }
            }
        }
        
        return (value: values, alpha: alphas)
    }
    
    private func calculateBitmatData(_ data: RawData) -> UnsafeMutablePointer<UInt8> {
        let bitmapData = UnsafeMutablePointer<UInt8>.allocate(capacity: config.width * config.height * 4)
        
        for i in 0 ..< config.width * config.height {
            if data.value[i] > 0 && data.alpha[i] > 0 {
                let color = self.ramp.color(for: data.value[i], alpha: data.alpha[i])
                
                let comps = color.components!
                let alpha = comps[3] * 255
                bitmapData[i*4 + 0] = UInt8(comps[0] * alpha)
                bitmapData[i*4 + 1] = UInt8(comps[1] * alpha)
                bitmapData[i*4 + 2] = UInt8(comps[2] * alpha)
                bitmapData[i*4 + 3] = UInt8(alpha)
            } else {
                bitmapData[i*4 + 0] = UInt8(0)
                bitmapData[i*4 + 1] = UInt8(0)
                bitmapData[i*4 + 2] = UInt8(0)
                bitmapData[i*4 + 3] = UInt8(0)
            }
        }
        return bitmapData
    }
    
    private func renderImage(_ bitmapData: UnsafeMutablePointer<UInt8>) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        let context = CGContext(data: bitmapData, width: config.width, height: config.height, bitsPerComponent: 8, bytesPerRow: config.width * 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        let image = context?.makeImage()
        //DebugTileSource.save(MaplyTileID(x: 0, y: 0, level: 0), image: image!)
        return image
    }
    
    
    // coordinate in radians to 0 - pixels
    private func coordToPixelsX(_ rad: Float) -> Float {
        let scaled = (rad - config.bounds.ll.x) / (config.bounds.ur.x - config.bounds.ll.x)
        assert(0 <= scaled && scaled <= 1.0)
        return scaled * Float(config.width)
    }
    
    // coordinate in radians to 0 - pixels
    private func coordToPixelsY(_ rad: Float) -> Float {
        let scaled = (rad - config.bounds.ll.y) / (config.bounds.ur.y - config.bounds.ll.y)
        
        assert(0 <= scaled && scaled <= 1.0)
        return scaled * Float(config.height)
    }
    
    private func cropBox(_ bbox: MaplyBoundingBox) -> CGRect {
        let lx = coordToPixelsX(bbox.ll.x)
        let ly = coordToPixelsY(bbox.ll.y)
        
        let ux = coordToPixelsX(bbox.ur.x)
        let uy = coordToPixelsY(bbox.ur.y)
        
        let width = Int(round(ux - lx))
        let height = Int(round(uy - ly))
        
        assert(width == height)
        
        return CGRect(x: CGFloat(Int(round(lx))), y: CGFloat(config.height - Int(round(uy))), width: CGFloat(width), height: CGFloat(height))
    }
    
    func render(_ tileID: MaplyTileID, bbox: MaplyBoundingBox, imageSize: Int) -> UIImage? {
        if output == nil {
            synced {
                // make sure we were the first thread to acquire the lock
                if self.output == nil {
                    self.generateOutput()
                }
            }
        }
        
        let crop = cropBox(bbox)
        if let cropped = output?.cropping(to: crop) {
            return UIImage(cgImage: cropped)
        } else {
            return nil
        }
    }

    
    
    func synced(_ closure: () -> ()) {
        objc_sync_enter(self)
        closure()
        objc_sync_exit(self)
    }
    
    func timer<T>(_ title:String, _ operation:() -> T) -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let res = operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("\(title): \(timeElapsed) s")
        return res
    }

}
