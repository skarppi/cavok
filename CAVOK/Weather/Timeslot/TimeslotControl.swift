//
//  TimeslotControl.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 21.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class TimeslotControl: UISegmentedControl {
    
    private static let clearImage = image(color: UIColor.clear)
    
    override var selectedSegmentIndex: Int {
        didSet {
            let segments = self.segments()
            if oldValue != -1 {
                segments[oldValue].layer.borderWidth = 0
            }
            segments[selectedSegmentIndex].layer.borderWidth = 3
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setBackgroundImage(TimeslotControl.clearImage, for: .normal, barMetrics: .default)
        setBackgroundImage(TimeslotControl.clearImage, for: .selected, barMetrics: .default)
        
        setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.black], for: .selected)
    }
    
    func updateSegment(color: UIColor, at segment: Int) {
        let view = segments()[segment]
        view.backgroundColor = color
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesMoved(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            
            if let index = segments().index(where: { $0.frame.contains(location)}) {
                if index != self.selectedSegmentIndex {
                    self.selectedSegmentIndex = index
                    sendActions(for: .valueChanged)
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    private func segments() -> [UIView] {
        return subviews.sorted(by: {(a, b) in
            return a.frame.origin.x < b.frame.origin.x
        })
    }
    
    private static func image(color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(rect)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
