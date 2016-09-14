//
//  Maply+Additions.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 07.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

extension MaplyBoundingBox {
    func inside(_ c: MaplyCoordinate) -> Bool {
        return ((self.ll.x < c.x) && (self.ll.y < c.y) && (c.x < self.ur.x) && (c.y < self.ur.y))
    }
}

extension MaplyCoordinate {
    static let kRadiansToDegrees = Float(180.0 / M_PI)
    static let kDegreesToRadians = Float(M_PI / 180.0)
    static let earthRadius = Float(6371.01) // Earth's radius in Kilometers
    
    var deg : MaplyCoordinate {
        get {
            return MaplyCoordinate(x: self.x * MaplyCoordinate.kRadiansToDegrees, y: self.y * MaplyCoordinate.kRadiansToDegrees)
        }
    }
    
    // finds a new location on a straight line towards a second location, given distance in kilometers.
    func locationAt(distance:Int, direction:Int) -> MaplyCoordinate {
        let lat1 = self.y
        let lon1 = self.x
        let dRad = Float(direction) * MaplyCoordinate.kDegreesToRadians
        
        let nD = Float(distance) //distance travelled in km
        let nC = nD / MaplyCoordinate.earthRadius
        let nA = acosf(cosf(nC)*cosf(Float(M_PI/2) - lat1) + sinf(Float(M_PI/2) - lat1)*sinf(nC)*cosf(dRad))
        let dLon = asin(sin(nC)*sin(dRad)/sin(nA))
        
        let lat2 = (Float(M_PI/2) - nA)
        let lon2 = (dLon + lon1)
        
        return MaplyCoordinateMake(lon2, lat2)
    }
}
