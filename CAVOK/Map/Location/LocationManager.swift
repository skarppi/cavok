//
//  LocationManager.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 06.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject {

    static let shared = LocationManager()

    let manager = CLLocationManager()

    @Published var lastLocation: CLLocationCoordinate2D?

    override private init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() {
        if CLLocationManager.locationServicesEnabled() {
            manager.requestWhenInUseAuthorization()
            manager.requestLocation()

            print("Location requested")
        } else {
            print("Location not enabled")
            lastLocation = nil
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .restricted:
            print("Restricted Access to location")
        case .denied:
            print("User denied access to location")
            lastLocation = nil
        case .notDetermined:
            print("Status not determined")
        default:
            print("Looking for location with status \(manager.authorizationStatus)")
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            lastLocation = location.coordinate
            print("Got location with accuracy \(location.horizontalAccuracy) to \(location.coordinate)")

            LastLocation.save(location: lastLocation!)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location", error)
        lastLocation = nil
    }
}
