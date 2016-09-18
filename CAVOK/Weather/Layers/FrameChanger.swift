//
//  FrameChanger.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 13.03.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class FrameChanger: MaplyActiveObject {
    let layer: MaplyQuadImageTilesLayer
    
    let period: Double = 1
    
    var startTime: TimeInterval?
    var sourceFrame: Float?
    var targetFrame: Float?
    
    init(layer: MaplyQuadImageTilesLayer) {
        self.layer = layer
        super.init()
    }
    
    func go(_ targetFrame: Int) {
        self.startTime = CFAbsoluteTimeGetCurrent()
        self.sourceFrame = layer.currentImage
        self.targetFrame = Float(targetFrame)
    }
    
    func hasUpdate() -> Bool {
        if let target = targetFrame {
            return layer.currentImage != target
        } else {
            return false
        }
    }
    
    func updateForFrame(_ frameInfo: AnyObject) {
        if let start = startTime, let source = sourceFrame, let target = targetFrame {
            let now = CFAbsoluteTimeGetCurrent()
            
            let pos = (now - start) / period
            if pos >= 1 {
                layer.currentImage = target
                startTime = nil
                sourceFrame = nil
                targetFrame = nil
            } else {
                layer.currentImage = source + Float(pos) * (target - source)
            }
        }
    }
}
