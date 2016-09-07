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
    
    var deg : MaplyCoordinate {
        get {
            return MaplyCoordinate(x: self.x * MaplyCoordinate.kRadiansToDegrees, y: self.y * MaplyCoordinate.kRadiansToDegrees)
        }
    }
}
