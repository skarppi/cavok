//
//  Station.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 21.10.12.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import RealmSwift

public class Station: Object {
    
    dynamic var identifier: String = ""
    dynamic var name: String = ""
    dynamic var latitude: Float = 0
    dynamic var longitude: Float = 0
    dynamic var elevation: Float = 0
    dynamic var hasMetar: Bool = false
    dynamic var hasTaf: Bool = false
    dynamic var timestamp: Date = Date()
    
    override open static func primaryKey() -> String? {
        return "identifier"
    }
    
    convenience init(identifier: String, name: String, latitude: Float, longitude: Float, elevation: Float, hasMetar: Bool, hasTaf: Bool) {
        self.init()
        self.identifier = identifier
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.hasMetar = hasMetar
        self.hasTaf = hasTaf
    }
    
    func coordinate() -> MaplyCoordinate {
        return MaplyCoordinateMakeWithDegrees(self.longitude, self.latitude)
    }
}
