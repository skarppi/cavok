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
            
            let (x, y) = config.bounds.normalize(localCoord)
            
            return HeatData(x: Int32(round(x * Float(config.width) - 0.5)), y: Int32(round(y * Float(config.height) - 0.5)), value: Int32(value))
        }

    }
    
    deinit {
        print("Canceling heatmap")
    }
    
    func process(priority: Bool) -> Promise<Void> {
        let qos: DispatchQoS = (priority) ? .userInitiated : .background
        
        return DispatchQueue.global().async(.promise, group: group, qos: qos) {
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
        
        let pixelData = output!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let (nx, ny) = config.bounds.normalize(localCoord)
        let x = Int(round(nx * Float(config.width)))
        let y = Int(round(ny * Float(config.height)))
        
        let pixelInfo = (config.width * (config.height - 1 - y) + x) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    func crop(bounds: MaplyBoundingBox, box: MaplyBoundingBox, width originalWidth: Int, height originalHeight: Int) -> CGRect {
        
        let ll = bounds.normalize(box.ll)
        let ur = bounds.normalize(box.ur)
        
        let x = Int(round(ll.x * Float(originalWidth)))
        let y = originalHeight - Int(round(Float(originalHeight) * ur.y))
        
        let width = Int(round(Float(originalWidth) * (ur.x - ll.x)))
        let height = Int(round(Float(originalHeight) * (ur.y - ll.y)))
        
        
        return CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height))
    }
    
    func render(_ tileID: MaplyTileID, bbox: MaplyBoundingBox, imageSize: Int) -> UIImage? {
        group.wait()
        
        if tileID.level < Int32(config.maxZoom) {
            
            let minX = max(config.bounds.ll.x, bbox.ll.x)
            let maxX = min(config.bounds.ur.x, bbox.ur.x)
            
            let minY = max(config.bounds.ll.y, bbox.ll.y)
            let maxY = min(config.bounds.ur.y, bbox.ur.y)
            
            let boundsCropped = MaplyBoundingBox(ll: MaplyCoordinate(x: minX, y: minY),
                                          ur: MaplyCoordinate(x: maxX, y: maxY))
            
            let crop = self.crop(bounds: config.bounds, box: boundsCropped, width: config.width, height: config.height)
            
            if let cropped = output?.cropping(to: crop) {
                UIGraphicsBeginImageContextWithOptions(CGSize(width: imageSize, height: imageSize), false, 0.0);
                
                let crop = self.crop(bounds: bbox, box: boundsCropped, width: imageSize, height: imageSize)
                
                UIImage(cgImage: cropped).draw(in: crop)
                let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
                return newImage
            } else {
                return nil
            }
        } else {
            let crop = self.crop(bounds: config.bounds, box: bbox, width: config.width, height: config.height)
            if let cropped = output?.cropping(to: crop) {
                return UIImage(cgImage: cropped)
            } else {
                return nil
            }
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
