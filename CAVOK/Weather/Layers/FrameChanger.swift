//
//  FrameChanger.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 13.03.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class FrameChanger: MaplyActiveObject {
    let loader: MaplyQuadImageFrameLoader
    
    // How long to animate from start to finish.
    let period: Double = 1
    
    var startTime: TimeInterval?
    var sourceFrame: Double?
    var targetFrame: Double?
    
    init(loader: MaplyQuadImageFrameLoader) {
        self.loader = loader
        super.init()
    }

    func go(_ targetFrame: Int) {
        self.startTime = CFAbsoluteTimeGetCurrent()
        self.sourceFrame = loader.getCurrentImage()
        self.targetFrame = Double(targetFrame)
    }
    
    @objc override func hasUpdate() -> Bool {
        if let target = targetFrame {
            return loader.getCurrentImage() != target
        } else {
            return false
        }
    }
    
    override func update(forFrame frameInfo: UnsafeMutableRawPointer) {
        if let start = startTime, let source = sourceFrame, let target = targetFrame {
            let now = CFAbsoluteTimeGetCurrent()
            
            let pos = (now - start) / period
            if pos >= period {
                loader.setCurrentImage(target)
                startTime = nil
                sourceFrame = nil
                targetFrame = nil
            } else {
                loader.setCurrentImage(source + Double(pos) * (target - source))
            }
        }
    }
}
