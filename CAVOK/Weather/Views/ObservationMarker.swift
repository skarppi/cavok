//
//  ObservationMarker.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 21.10.12.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class ObservationMarker : MaplyScreenMarker {
    
    init(obs: Observation) {
        super.init()
        self.userObject = obs
        self.loc = obs.station!.coordinate()
        self.size = CGSize(width: 10, height: 10)
        self.image = drawRect(condition: obs.conditionEnum)
    }
    
    private func drawRect(condition: WeatherConditions) -> UIImage {
        let size = self.size.width * 2
        UIGraphicsBeginImageContext(CGSize(width: size, height: size))
        
        if let context = UIGraphicsGetCurrentContext() {
            context.setLineWidth(1)
            context.setFillColor(ColorRamp.color(forCondition: condition).cgColor)
            context.setStrokeColor(UIColor.black.cgColor)
            context.addEllipse(in: CGRect(x: 1, y: 1, width: size - 2, height: size - 2))
            context.drawPath(using: .fillStroke)
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
