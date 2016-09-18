//
//  WeatherConfig.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 08.03.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class WeatherConfig {
    let coordSystem = MaplySphericalMercator(webStandard: ())

    let region: WeatherRegion
    
    // width and height in pixels
    let width: Int
    let height: Int
    
    // padding in kilometers
    let padding: Int
    
    // radius of weather station in pixels
    let radius: Int
    
    // local coordinates
    let bounds: MaplyBoundingBox
    
    let zoom: Int = 5
    
    let tilesize = 256
    
    let ll: MaplyTileID
    let ur: MaplyTileID
    
    init(region: WeatherRegion) {
        self.region = region
        
        self.padding = min(region.radius / 3, 300)
        
        let bbox = region.bbox(padding: padding)
        let (ll, ur) = bbox.tiles(zoom: Int32(zoom))
        self.ll = ll
        self.ur = ur
        
        self.bounds = coordSystem.geo(toLocalBox: MaplyBoundingBox(ll: ll.coordinate, ur: ur.coordinate))
        
        let resolution = 156543.03 * cos(region.center.y) / pow(2.0, Float(zoom)) //meters/pixel
        
        let scale = Double(tilesize) * pow(2.0, Double(zoom))
        self.width = Int(round(Double(bounds.ur.x - bounds.ll.x) / (2 * M_PI) * scale))
        self.height = Int(round(Double(bounds.ur.y - bounds.ll.y) / (2 * M_PI) * scale))
        self.radius = Int(round(Float(padding * 1000) / resolution))
    }
}
