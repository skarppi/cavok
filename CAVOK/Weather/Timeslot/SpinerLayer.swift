//
//  SpinerLayer.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 19.08.2017.
//  Copyright © 2017 Juho Kolehmainen. All rights reserved.
//

import Foundation
import UIKit

// https://github.com/entotsu/TKSubmitTransition/blob/master/SubmitTransition/Classes/SpinerLayer.swift
class SpinerLayer: CAShapeLayer {
    
    init(frame:CGRect) {
        super.init()
        
        let radius:CGFloat = (frame.height / 2)
        self.frame = CGRect(x: 0, y: 0, width: frame.height, height: frame.height)
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let startAngle = 0 - (Double.pi / 2)
        let endAngle = Double.pi * 2 - (Double.pi / 2)
        self.path = UIBezierPath(arcCenter: center, radius: radius, startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: true).cgPath
        
        self.fillColor = nil
        self.strokeColor = UIColor.black.cgColor
        self.lineWidth = 1
        
        self.strokeEnd = 0.4
        self.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func animation() {
        self.isHidden = false
        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        rotate.fromValue = 0
        rotate.toValue = Double.pi * 2
        rotate.duration = 0.4
        rotate.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        rotate.repeatCount = HUGE
        rotate.fillMode = kCAFillModeForwards
        rotate.isRemovedOnCompletion = false
        self.add(rotate, forKey: rotate.keyPath)
        
    }
    
    func stopAnimation() {
        self.isHidden = true
        self.removeAllAnimations()
    }
}
