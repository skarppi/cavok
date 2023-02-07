//
//  LastSession.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 07.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class LastSession {

    class func load() -> (center: MaplyCoordinate, height: Float)? {
        if let lastSession = UserDefaults.cavok?.dictionary(forKey: "LastSession") as? [String: Float] {
            if let longitude = lastSession["longitude"],
               let latitude = lastSession["latitude"],
               let height = lastSession["height"] {
                // print("Restoring location \(lastSession)")
                return (MaplyCoordinateMakeWithDegrees(longitude, latitude), height)
            }
        }
        return nil
    }

    class func save(center: MaplyCoordinate, height: Double) {
        let lastSession: [String: Any] = [
            "longitude": center.deg.x,
            "latitude": center.deg.y,
            "height": height
        ]
        print("Saving location \(lastSession)")

        let defaults = UserDefaults.cavok
        defaults?.set(lastSession, forKey: "LastSession")
        defaults?.synchronize()
    }
}
