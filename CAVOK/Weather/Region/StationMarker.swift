//
//  StationMarker.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 10/10/2016.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class StationMarker: MaplyScreenMarker {

    static let diameter = 10

    static let markerImage: UIImage = {
        let size = StationMarker.diameter * 2
        UIGraphicsBeginImageContext(CGSize(width: size, height: size))

        if let context = UIGraphicsGetCurrentContext() {
            context.setLineWidth(1)
            context.setFillColor(UIColor.black.withAlphaComponent(0.8).cgColor)
            context.setStrokeColor(UIColor.black.cgColor)
            context.addEllipse(in: CGRect(x: 1, y: 1, width: size - 2, height: size - 2))
            context.drawPath(using: .fillStroke)
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }()

    init(station: Station) {
        super.init()
        self.userObject = station
        self.loc = station.coordinate()
        self.size = CGSize(width: StationMarker.diameter, height: StationMarker.diameter)
        self.image = StationMarker.markerImage
    }
}
