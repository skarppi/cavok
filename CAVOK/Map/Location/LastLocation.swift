//
//  LastLocation.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 15.10.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import CoreLocation

struct LastLocation: Codable {

    let latitude: Double
    let longitude: Double
    let date: Date

    init(_ coordinate: CLLocationCoordinate2D) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
        date = Date()
    }

    static func load() -> CLLocationCoordinate2D? {
        if let location: LastLocation = UserDefaults.read() {
            return CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        }
        return nil
    }

    static func save(location: CLLocationCoordinate2D) {
        UserDefaults.store(LastLocation(location))
    }
}
