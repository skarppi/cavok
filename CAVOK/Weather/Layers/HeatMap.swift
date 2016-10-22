//
//  HeatMap.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 12.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

struct HeatData {
    let x: Int32
    let y: Int32
    let value: Int32
}

class HeatMap {
    
    let observations: [Observation]
    
    let config: WeatherConfig

    let group = DispatchGroup()
    
    var output: CGImage? = nil
    
    init(observations: [Observation], config: WeatherConfig, observationValue: (Observation) -> Int?, ramp: ColorRamp, frame: Int, priority: Bool) {
        
        self.observations = observations
        
        self.config = config
        
        let input: [HeatData] = observations.flatMap { obs in
            if let value = observationValue(obs) {
                let coord = config.coordSystem.geo(toLocal: obs.station!.coordinate())
                let x = Int(round(coordToPixelsX(coord.x) - 0.5))
                let y = Int(round(coordToPixelsY(coord.y) - 0.5))
                
                return HeatData(x: Int32(x), y: Int32(y), value: Int32(value))
            } else {
                return nil
            }
        }
        
        guard !input.isEmpty else {
            return
        }
        
        let qos: DispatchQoS.QoSClass = (priority) ? .userInitiated : .background
        
        DispatchQueue.global(qos: qos).async(group: group, execute: DispatchWorkItem {
            self.timer("end frame \(frame)") {
                print("start frame \(frame)")
                
                self.output = HeatMapGPU(input: input, config: config, steps: ramp.steps).render()
                
                if self.output == nil {
                    self.output = HeatMapCPU(input: input, config: config, ramp: ramp).render()
                }
            }
        })
    }
    
    deinit {
        print("Canceling heatmap")
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
        group.wait()
        
        let crop = cropBox(bbox)
        if let cropped = output?.cropping(to: crop) {
            return UIImage(cgImage: cropped)
        } else {
            return nil
        }
    }
    
    func timer<T>(_ title:String, _ operation:() -> T) -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let res = operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("\(title): \(timeElapsed) s")
        return res
    }
}
