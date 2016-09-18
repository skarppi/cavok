//
//  RegionHelpers.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 13.08.14.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import CoreLocation

class WeatherRegion {
    // bounding box
    var minLat: Float
    var maxLat: Float
    var minLon: Float
    var maxLon: Float
    
    // radius of the circle
    var radius: Int {
        didSet {
            let recalculated = WeatherRegion(center: center, radius: radius)
            copyBoundaries(from: recalculated)
        }
    }

    // center of the circle
    var center: MaplyCoordinate {
        get {
            let latitude = minLat + (maxLat - minLat) / 2
            let longitude = minLon + (maxLon - minLon) / 2
            
            return MaplyCoordinateMakeWithDegrees(longitude, latitude)
        }
        set {
            let recalculated = WeatherRegion(center: newValue, radius: radius)
            copyBoundaries(from: recalculated)
        }
    }
    
    init(minLat: Float, maxLat: Float, minLon: Float, maxLon: Float, radius: Int) {
        self.minLat = minLat
        self.maxLat = maxLat
        self.minLon = minLon
        self.maxLon = maxLon
        self.radius = radius
    }
    
    init(center: MaplyCoordinate, radius: Int) {
        let top = center.locationAt(distance: radius, direction:0)
        let right = center.locationAt(distance: radius, direction:90)
        let bottom = center.locationAt(distance: radius, direction:180)
        let left = center.locationAt(distance: radius, direction:270)
        
        self.minLat = bottom.deg.y
        self.maxLat = top.deg.y
        self.minLon = left.deg.x
        self.maxLon = right.deg.x
        self.radius = radius
    }
    
    private func copyBoundaries(from: WeatherRegion) {
        self.minLat = from.minLat
        self.maxLat = from.maxLat
        self.minLon = from.minLon
        self.maxLon = from.maxLon
    }
    
    static func load() -> WeatherRegion? {
        let defaults = UserDefaults.standard
        if let coordinates = defaults.dictionary(forKey: "coordinates") as? [String: Float] {
            
            return WeatherRegion(
                minLat: coordinates["minLat"]!,
                maxLat: coordinates["maxLat"]!,
                minLon: coordinates["minLon"]!,
                maxLon: coordinates["maxLon"]!,
                radius: Int(coordinates["radius"]!)
            )
        } else {
            return nil
        }
    }
    
    func save() -> Bool {
        let coordinates = [
            "minLat": minLat,
            "maxLat": maxLat,
            "minLon": minLon,
            "maxLon": maxLon,
            "radius": radius
            ] as [String : Any]
        
        print("Saving weather region \(coordinates)")
        
        let defaults = UserDefaults.standard
        defaults.set(coordinates, forKey:"coordinates")
        return defaults.synchronize()
    }
    
    func inRange(latitude: Float, longitude: Float) -> Bool {
        let deg = center.deg
        let location = CLLocation(latitude: Double(deg.y), longitude:Double(deg.x))
        let target = CLLocation(latitude: CLLocationDegrees(latitude), longitude:CLLocationDegrees(longitude))
        
        let distance = location.distance(from: target)
        return Int(distance) <= radius * 1000
    }
    
    func bbox(padding: Int) -> MaplyBoundingBox {
        let ll = MaplyCoordinateMakeWithDegrees(minLon, minLat).locationAt(distance: padding, direction: 225)
        let ur = MaplyCoordinateMakeWithDegrees(maxLon, maxLat).locationAt(distance: padding, direction: 45)
        
        return MaplyBoundingBox(ll: ll, ur: ur)
    }
}
