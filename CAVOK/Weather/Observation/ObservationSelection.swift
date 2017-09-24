//
//  ObservationSelection.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 27.07.2017.
//  Copyright © 2017 Juho Kolehmainen. All rights reserved.
//

import Foundation

class ObservationSelection : MaplyScreenMarker {
    
    init(obs: Observation) {
        super.init()
        userObject = obs
        loc = obs.station!.coordinate()
        size = CGSize(width: 30, height: 30)
        
        layoutImportance = 2.0
        
        let center = ObservationMarker(obs: obs).image as! UIImage
        
        let backgroundImage = UIImage(named: "Crosshair")!
        
        UIGraphicsBeginImageContextWithOptions(backgroundImage.size, false, 0.0)
        backgroundImage.draw(in: CGRect(x: 0.0, y: 0.0, width: backgroundImage.size.width, height: backgroundImage.size.height))
        center.draw(in: CGRect(x: backgroundImage.size.width - center.size.width - 1, y: backgroundImage.size.height - center.size.height - 1, width: center.size.width / 2, height: center.size.height / 2))
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

    }
    
}
