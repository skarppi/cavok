//
//  RegionCalloutView.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 4.11.12.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class RegionAnnotationView : MaplyAnnotation {
    
    let region: WeatherRegion
    
    let closed: (WeatherRegion) -> Void
    
    let resized: (WeatherRegion) -> Void
    
    init(region: WeatherRegion, closed: @escaping (WeatherRegion) -> Void, resized: @escaping (WeatherRegion) -> Void) {
        self.region = region
        self.closed = closed
        self.resized = resized
        super.init()
        
        let label = UILabel(frame:CGRect(x: 0, y: 0, width: 60, height: 25))
        label.font = UIFont.systemFont(ofSize: 17)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.text = "\(region.radius)km"
        
        contentView = label
        
        let changeRadiusStepper = UIStepper(frame:CGRect(x: 0.0, y: 0.0, width: 25.0, height: 25.0))
        changeRadiusStepper.minimumValue = 100
        changeRadiusStepper.maximumValue = 1000
        changeRadiusStepper.stepValue = 100
        changeRadiusStepper.value = Double(region.radius)
        changeRadiusStepper.addTarget(self, action: #selector(RegionAnnotationView.radiusChanged(_:)), for: UIControlEvents.valueChanged)
        
        leftAccessoryView = changeRadiusStepper
        
        let removeRegionButton = UIButton(type: UIButtonType.system)
        removeRegionButton.setTitle("Ok", for:UIControlState())
        removeRegionButton.frame = CGRect(x: 0.0, y: 0.0, width: 25.0, height: 25.0)
        removeRegionButton.addTarget(self, action: #selector(RegionAnnotationView.done(_:)), for: UIControlEvents.touchUpInside)
        
        rightAccessoryView = removeRegionButton
    }
    
    func radiusChanged(_ stepper: UIStepper) {
        region.radius = Int(stepper.value)
        
        if let label = contentView as? UILabel {
            label.text = "\(region.radius)km"
        }
        resized(region)
    }
    
    func done(_ button: UIButton) {
        closed(region)
    }
}
