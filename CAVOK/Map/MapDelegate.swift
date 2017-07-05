//
//  MapDelegate.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 27/09/2016.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import Pulley

public struct Legend {
    var unit: String
    var gradient: [CGColor]
    var titles: [String]
}

public protocol MapDelegate: DrawerDelegate {
    
    func clearAnnotations(ofType: MaplyAnnotation.Type?)
    
    func findComponent(ofType: NSObject.Type) -> NSObject?
    
    func addComponents(key: NSObject, value: MaplyComponentObject)
    
    func clearComponents(ofType: NSObject.Type?)
    
    var mapView: WhirlyGlobeViewController! {
        get
    }
    
    var pulley: PulleyViewController! {
        get
    }
}
