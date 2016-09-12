//
//  RegionHelpers.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 13.08.14.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import CoreLocation

struct WeatherRegion {
    // bounding box
    var minLat: Float
    var maxLat: Float
    var minLon: Float
    var maxLon: Float
    
    // radius of the circle
    var radius: Int

    // center of the circle
    var center: MaplyCoordinate {
        get {
            let latitude = minLat + (maxLat - minLat) / 2
            let longitude = minLon + (maxLon - minLon) / 2
            
            return MaplyCoordinateMakeWithDegrees(longitude, latitude)
        }
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
    
}
