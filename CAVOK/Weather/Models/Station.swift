//
//  Station.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 21.10.12.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import RealmSwift
import CoreLocation

enum WeatherSource: String, PersistableEnum {
    case aws
    case adds
}

public class Station: Object {

    @Persisted(primaryKey: true) var identifier: String = ""
    @Persisted var name: String = ""
    @Persisted var latitude: Float = 0
    @Persisted var longitude: Float = 0
    @Persisted var elevation: Float = 0
    @Persisted var source: WeatherSource
    @Persisted var hasMetar: Bool = false
    @Persisted var hasTaf: Bool = false
    @Persisted var timestamp: Date = Date()
    @Persisted var favorite: Bool = false

    convenience init(identifier: String,
                     name: String,
                     latitude: Float,
                     longitude: Float,
                     elevation: Float,
                     source: WeatherSource,
                     hasMetar: Bool,
                     hasTaf: Bool) {
        self.init()
        self.identifier = identifier
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.source = source
        self.hasMetar = hasMetar
        self.hasTaf = hasTaf
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(Double(latitude), Double(longitude))
    }
}
