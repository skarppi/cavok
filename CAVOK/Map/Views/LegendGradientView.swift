//
//  LegendGradientView.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 17/10/2016.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class LegendGradientView : UIView {

    
    func gradient(ramp: [CGColor]) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [ramp[0],ramp[1],ramp[1],ramp[2],ramp[2],ramp[3],ramp[3],ramp[4],ramp[4],ramp[5]]
        gradientLayer.locations = [ 0.15, 0.18, 0.27, 0.36, 0.45, 0.54, 0.63, 0.72, 0.81, 0.85]
        gradientLayer.frame.size = self.frame.size
        gradientLayer.frame.origin = CGPoint.zero
        
        self.layer.addSublayer(gradientLayer)
    }
}

