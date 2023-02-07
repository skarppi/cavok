//
//  CLLocation+Additions.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 6.2.2023.
//

import CoreLocation

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

extension CLLocationCoordinate2D {
    static let earthRadius = 6371.01 // Earth's radius in Kilometers

    // finds a new location on a straight line towards a second location, given distance in kilometers.
    func locationAt(kilometers: Float, direction: Float) -> CLLocationCoordinate2D {
        let lat1 = Double.pi/2 - self.latitude.degreesToRadians
        let dRad = Double(direction).degreesToRadians

        let numC = Double(kilometers) / CLLocationCoordinate2D.earthRadius

        let numA = acos(cos(numC)*cos(lat1) + sin(lat1)*sin(numC)*cos(dRad))
        let dLon = asin(sin(numC)*sin(dRad)/sin(numA))

        return CLLocationCoordinate2D(
            latitude: (Double.pi/2 - numA).radiansToDegrees,
            longitude: dLon.radiansToDegrees + self.longitude
        )
    }
}
