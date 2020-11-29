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
    let padding: Float
    
    // radius of weather station in pixels
    let radius: Int
    
    // local coordinates
    let bounds: MaplyBoundingBox
    
    let minZoom: Int = 4
    
    let maxZoom: Int = 6
    
    let tilesize = 256
    
    let tiles: [(ll: MaplyTileID, ur: MaplyTileID)]
    
    init(region: WeatherRegion) {
        self.region = region
        
        self.padding = min(region.radius / 2, 300)
        
        let bbox = region.bbox(padding: padding)
        let tiles = (0...maxZoom).map { zoom in
            bbox.tiles(zoom: Int32(zoom))
        }
        self.tiles = tiles
        
        let tile = tiles[maxZoom]
        
        let bounds = coordSystem.geo(toLocalBox: MaplyBoundingBox(ll: tile.ll.coordinate, ur: tile.ur.coordinate))
        self.bounds = bounds
        
        let resolution = 156543.03 * cos(region.center.y) / pow(2.0, Float(maxZoom)) //meters/pixel
        
        let scale = Double(tilesize) * pow(2.0, Double(maxZoom))
        self.width = Int(round(Double(bounds.ur.x - bounds.ll.x) / (2 * Double.pi) * scale))
        self.height = Int(round(Double(bounds.ur.y - bounds.ll.y) / (2 * Double.pi) * scale))
        self.radius = Int(round(Float(padding * 1000) / resolution))
    }
}
