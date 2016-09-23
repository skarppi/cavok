//
//  MapModule.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 20.01.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

protocol MapModule {
    init(delegate: MapDelegate)
    
    func didTapAt(coord: MaplyCoordinate)
    
    func refresh()
    
    func configure(open: Bool, userLocation: MaplyCoordinate?)
    
    func render(frame: Int?)
    
    func annotation(object: Any, parentFrame: CGRect) -> UIView?
}

public protocol MapDelegate {
    func setStatus(text: String?, color: UIColor)
    
    func setStatus(error: Error)
    
    func setTimeslots(slots: [Date])
    
    func clearAnnotations(ofType: MaplyAnnotation.Type?)
    
    func findComponent(ofType: NSObject.Type) -> NSObject?
    
    func addComponents(key: NSObject, value: MaplyComponentObject)
    
    func clearComponents(ofType: NSObject.Type?)
    
    var mapView: WhirlyGlobeViewController! {
        get
    }
}
