//
//  LastLocation.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 15.10.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import CoreLocation

class LastLocation {

    class func load() -> CLLocationCoordinate2D? {
        if let location = UserDefaults.cavok?.dictionary(forKey: "LastLocation") {
            if let longitude = location["longitude"] as? Double,
               let latitude = location["latitude"] as? Double {
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }
        return nil
    }

    class func save(location: CLLocationCoordinate2D) {
        let lastLocation: [String: Any] = [
            "longitude": location.longitude,
            "latitude": location.latitude,
            "date": Date()
        ]
        let defaults = UserDefaults.cavok
        defaults?.set(lastLocation, forKey: "LastLocation")
        defaults?.synchronize()
    }
}
