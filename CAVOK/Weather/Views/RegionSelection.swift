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
        let radius = CGFloat(200)
        
        UIGraphicsBeginImageContext(CGSize(width: radius, height: radius))
        
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(2)
        
        //let path = CGPathCreateMutable()
        //CGPathAddArc(path, nil, CGFloat(centerPoint.x), CGFloat(centerPoint.y), CGFloat(radius), CGFloat(0.0), CGFloat(2.0 * M_PI), true)
        
        let blue = UIColor.blue
        
        context?.setFillColor(blue.withAlphaComponent(0.2).cgColor)
        context?.setStrokeColor(blue.withAlphaComponent(0.7).cgColor)
        context?.addEllipse(in: CGRect(x: 0.0, y: 0.0, width: radius-2, height: radius-2))
        context?.drawPath(using: CGPathDrawingMode.fillStroke)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image!
        
        //let centerPoint = self.pointForMapPoint(MKMapPointForCoordinate(center))
        //let radius = MKMapPointsPerMeterAtLatitude(center.latitude) * region.radius
        //CGPathAddArc(path, nil, CGFloat(centerPoint.x), CGFloat(centerPoint.y), CGFloat(radius), CGFloat(0.0), CGFloat(2.0 * M_PI), true)
        
    }
}
