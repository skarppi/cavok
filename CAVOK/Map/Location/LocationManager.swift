//
//  LocationManager.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 06.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    let manager = CLLocationManager()
    
    var fulfill: (MaplyCoordinate) -> Void
    var reject: (String) -> Void
    
    init(fulfill: @escaping (MaplyCoordinate) -> Void, reject: @escaping (String) -> Void) {
        self.fulfill = fulfill
        self.reject = reject
    }

    func requestLocation() {
        if CLLocationManager.locationServicesEnabled() {
            manager.delegate = self;
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            
            manager.requestWhenInUseAuthorization()
            manager.requestLocation()

            print("Location requested")
        } else {
            reject("Location not enabled")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .restricted:
            print("Restricted Access to location")
        case .denied:
            print("User denied access to location")
            reject("Location not allowed")
        case .notDetermined:
            print("Status not determined")
        default:
            print("Looking for location with status \(manager.authorizationStatus)")
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let eventDate = location.timestamp
            let howRecent = abs(eventDate.timeIntervalSinceNow)
            print("Got location with accuracy \(location.horizontalAccuracy) is \(howRecent) old");
            let coordinate = MaplyCoordinateMakeWithDegrees(Float(location.coordinate.longitude), Float(location.coordinate.latitude))
            fulfill(coordinate)
            
            LastLocation.save(location: coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location", error)
        reject("Failed to get location")
    }
}

