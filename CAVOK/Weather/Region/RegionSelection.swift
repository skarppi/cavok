//
//  RegionSelection.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 4.11.12.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class RegionSelection: MaplyShapeCircle {

    let desc: [String: Any] = [
        kMaplyFade: 1.0,
        kMaplyColor: UIColor.blue.withAlphaComponent(0.2),
        kMaplyZBufferRead: false,
        kMaplyShapeSampleX: 100
    ]

    var region: WeatherRegion {
        didSet {
            update()
        }
    }

    init(region: WeatherRegion) {
        self.region = region

        super.init()

        height = 0
        update()
    }

    func update() {
        center = region.center.maplyCoordinate
        radius = (region.ur.y - region.ll.y ) / 2
    }
}
