//
//  RegionDrawerController.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 01.06.2017.
//  Copyright © 2017 Juho Kolehmainen. All rights reserved.
//

import Foundation
import Pulley

class RegionDrawerController: UIViewController {
    
    @IBOutlet var radius: UILabel!
    
    @IBOutlet var status: UILabel!
    
    @IBOutlet var stepper: UIStepper!
    
    private var region: WeatherRegion!

    private var resized: (WeatherRegion) -> Void = { (r: WeatherRegion) -> Void in
    }
    
    private var closed: (WeatherRegion) -> Void = { (r: WeatherRegion) -> Void in
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        stepper.value = Double(self.region.radius)
        
        radiusChanged(stepper)
    }
    
    func setup(region: WeatherRegion, closed: @escaping (WeatherRegion) -> Void, resized: @escaping (WeatherRegion) -> Void) {
        self.region = region
        self.closed = closed
        self.resized = resized
    }
    
    func status(text: String) {
        status.text = text
    }
    
    @IBAction func radiusChanged(_ stepper: UIStepper) {
        region.radius = Int(stepper.value)
        
        radius.text = "Radius \(region.radius) km"
        
        if stepper.value >= 1000 {
            stepper.stepValue = 500
        } else if stepper.value >= 500 {
            stepper.stepValue = 200
        } else {
            stepper.stepValue = 100
        }

        resized(region)
    }
    
    @IBAction func center(_ button: UIButton) {
        if let location = LastLocation.load() {
            region.center = location
            resized(region)
        } else {
            status(text: "Unknown location")
        }
    }
    
    @IBAction func close(_ button: UIButton) {
        closed(region)
    }

}

extension RegionDrawerController: PulleyDrawerViewControllerDelegate {
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.closed, .collapsed, .partiallyRevealed]
    }
    
    func collapsedDrawerHeight() -> CGFloat {
        return 75
    }
    
    func partialRevealDrawerHeight() -> CGFloat {
        return 150
    }
}

