//
//  Cavok+Additions.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 6.2.2023.
//

import Foundation

extension Station {
    func coordinate() -> MaplyCoordinate {
        return MaplyCoordinateMakeWithDegrees(self.longitude, self.latitude)
    }
}
