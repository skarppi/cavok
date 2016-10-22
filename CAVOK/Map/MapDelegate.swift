//
//  MapDelegate.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 27/09/2016.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

public struct Legend {
    var unit: String
    var gradient: [CGColor]
    var titles: [String]
}

public protocol MapDelegate {
    func setStatus(text: String?, color: UIColor)
    
    func setStatus(error: Error)
    
    func loaded(frame:Int?, timeslots: [Timeslot], legend: Legend)
    
    func clearAnnotations(ofType: MaplyAnnotation.Type?)
    
    func findComponent(ofType: NSObject.Type) -> NSObject?
    
    func addComponents(key: NSObject, value: MaplyComponentObject)
    
    func clearComponents(ofType: NSObject.Type?)
    
    var mapView: WhirlyGlobeViewController! {
        get
    }
}
