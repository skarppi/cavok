//
//  UserMarker.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 15.02.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class UserMarker: MaplyScreenMarker {

    init(coordinate: MaplyCoordinate) {
        super.init()
        image = UIImage(named: "Location")
        loc = coordinate
        size = CGSize(width: 12, height: 12)
        layoutImportance = 1.0
    }
}
