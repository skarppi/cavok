//
//  LastLocation.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 15.10.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class LastLocation {

    class func load() -> MaplyCoordinate? {
        if let location = UserDefaults.standard.dictionary(forKey: "LastLocation") {
            if let longitude = location["longitude"] as? Float,
                let latitude = location["latitude"] as? Float {
                return MaplyCoordinateMakeWithDegrees(longitude, latitude)
            }
        }
        return nil
    }

    class func save(location: MaplyCoordinate) {
        let lastLocation: [String: Any] = [
            "longitude": location.deg.x,
            "latitude": location.deg.y,
            "date": Date()
        ]
        let defaults = UserDefaults.standard
        defaults.set(lastLocation, forKey: "LastLocation")
        defaults.synchronize()
    }
}
