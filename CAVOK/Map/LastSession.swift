//
//  LastSession.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 07.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class LastSession {
    
    class func restore() -> (center: MaplyCoordinate, height: Float)? {
        if let lastSession = UserDefaults.standard.dictionary(forKey: "LastSession") as? [String : Float] {
            if let longitude = lastSession["longitude"],
                let latitude = lastSession["latitude"],
                let height = lastSession["height"] {
                print("Restoring location \(lastSession)")
                return (MaplyCoordinateMakeWithDegrees(longitude, latitude), height)
            }
        }
        return nil
    }
    
    class func store(center: MaplyCoordinate, height: Double) {
        let lastSession: [String : Any] = [
            "longitude" : center.deg.x,
            "latitude" : center.deg.y,
            "height": height
            ]
        print("Saving location \(lastSession)")
        
        let defaults = UserDefaults.standard
        defaults.set(lastSession, forKey:"LastSession")
        defaults.synchronize()
    }
}
