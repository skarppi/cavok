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

    let latitude: Float
    let longitude: Float
    let height: Float
    let timestamp: Date

    var coordinate: MaplyCoordinate {
        return MaplyCoordinateMakeWithDegrees(longitude, latitude)
    }

    static func load() -> LastSession? {
        return UserDefaults.read()
    }

    static func save(center: MaplyCoordinate, height: Float) {

        let session = LastSession(latitude: center.deg.y, longitude: center.deg.x, height: height, timestamp: Date())

        print("Saving location \(session)")

        UserDefaults.store(session)
    }
}
