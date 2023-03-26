//
//  ObservationSelection.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 27.07.2017.
//  Copyright © 2017 Juho Kolehmainen. All rights reserved.
//

import Foundation

class ObservationSelection: MaplyScreenMarker {

    init(obs: Observation) {
        super.init()
        userObject = obs
        loc = obs.station!.coordinate.maplyCoordinate
        size = CGSize(width: 30, height: 30)

        layoutImportance = 2.0

        if let center = ObservationMarker(obs: obs).image as? UIImage {

            let bgImage = UIImage(named: "Crosshair")!

            UIGraphicsBeginImageContextWithOptions(bgImage.size, false, 0.0)
            bgImage.draw(in: CGRect(x: 0.0, y: 0.0, width: bgImage.size.width, height: bgImage.size.height))
            center.draw(in: CGRect(x: bgImage.size.width - center.size.width - 1,
                                   y: bgImage.size.height - center.size.height - 1,
                                   width: center.size.width / 2,
                                   height: center.size.height / 2))
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
    }

}
