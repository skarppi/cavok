//
//  LastSession.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 07.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import CoreLocation

struct LastSession: Codable {

    let latitude: Double
    let longitude: Double
    let height: Float
    let timestamp: Date

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }

    static func load() -> LastSession? {
        return UserDefaults.read()
    }

    static func save(center: CLLocationCoordinate2D, height: Float) {

        let session = LastSession(latitude: center.latitude, longitude: center.longitude, height: height, timestamp: Date())

        print("Saving location \(session)")

        UserDefaults.store(session)
    }
}
