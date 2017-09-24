//
//  RegionSelection.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 4.11.12.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class RegionSelection : MaplySticker {
    
    var region: WeatherRegion {
        didSet {
            update()
        }
    }
    
    init(region: WeatherRegion) {
        self.region = region
        super.init()
        
        update()
        
        image = render()
    }
    
    func update() {
        ll = MaplyCoordinateMakeWithDegrees(region.minLon, region.minLat)
        ur = MaplyCoordinateMakeWithDegrees(region.maxLon, region.maxLat)
    }
    
    func render() -> UIImage {
        let radius = 512
        
        UIGraphicsBeginImageContext(CGSize(width: radius, height: radius))
        
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(2)
        
        let blue = UIColor.blue
        
        context?.setFillColor(blue.withAlphaComponent(0.2).cgColor)
        context?.setStrokeColor(blue.withAlphaComponent(0.7).cgColor)
        context?.addEllipse(in: CGRect(x: 2, y: 2, width: radius-4, height: radius-4))
        context?.drawPath(using: CGPathDrawingMode.fillStroke)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image!
    }
}
