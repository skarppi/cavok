//
//  HeatMap.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 12.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import PromiseKit

struct HeatData {
    let x: Int32
    let y: Int32
    let value: Int32
}

class HeatMap {
    
    let index: Int
    
    let observations: [Observation]
    
    let config: WeatherConfig

    let presentation: ObservationPresentation
    
    let group = DispatchGroup()

    var input: [HeatData] = []
    
    var output: CGImage? = nil
    
    init(index: Int, observations: [Observation], config: WeatherConfig, presentation: ObservationPresentation) {
        self.index = index
        self.observations = observations
        self.config = config
        self.presentation = presentation
        
        self.input = observations.flatMap { obs in
            guard let value = presentation.mapper(obs).value else {
                return nil
            }
            
            let localCoord = config.coordSystem.geo(toLocal: obs.station!.coordinate())
            guard config.bounds.inside(localCoord) else {
                return nil
            }
            
            let x = Int(round(coordToPixelsX(localCoord.x) - 0.5))
            let y = Int(round(coordToPixelsY(localCoord.y) - 0.5))
            
            return HeatData(x: Int32(x), y: Int32(y), value: Int32(value))
        }

    }
    
    deinit {
        print("Canceling heatmap")
    }
    
    // local coordinate in radians to 0 - pixels
    private func coordToPixelsX(_ rad: Float) -> Float {
        let scaled = (rad - config.bounds.ll.x) / (config.bounds.ur.x - config.bounds.ll.x)
        assert(0 <= scaled && scaled <= 1.0)
        return scaled * Float(config.width)
    }
    
    // local coordinate in radians to 0 - pixels
    private func coordToPixelsY(_ rad: Float) -> Float {
        let scaled = (rad - config.bounds.ll.y) / (config.bounds.ur.y - config.bounds.ll.y)
        
        assert(0 <= scaled && scaled <= 1.0)
        return scaled * Float(config.height)
    }
    
    func process(priority: Bool) -> Promise<Void> {
        let qos: DispatchQoS = (priority) ? .userInitiated : .background
        
        return DispatchQueue.global().promise(group: group, qos: qos) {
            self.timer("end frame \(self.index)") {
                print("start frame \(self.index)")
                
                self.output = HeatMapGPU(input: self.input, config: self.config, steps: self.presentation.ramp.steps).render()
                
                if self.output == nil {
                    self.output = HeatMapCPU(input: self.input, config: self.config, ramp: self.presentation.ramp).render()
                }
            }
        }
    }
    
    func color(for coordinate: MaplyCoordinate) -> UIColor {
        let localCoord = config.coordSystem.geo(toLocal: coordinate)
        
        guard config.bounds.inside(localCoord) else {
            return UIColor.clear
        }
        
        group.wait()
        
        let x = coordToPixelsX(localCoord.x)
        let y = coordToPixelsY(localCoord.y)
        
        let pixelData = output!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let pixelInfo = (config.width * (config.height - 1 - Int(y)) + Int(x)) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
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
