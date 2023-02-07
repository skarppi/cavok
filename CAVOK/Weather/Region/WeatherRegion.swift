//
//  WeatherRegion.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 13.08.14.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import CoreLocation
import Combine

class WeatherRegion: ObservableObject {
    // bounding box
    var minLat: Double
    var maxLat: Double
    var minLon: Double
    var maxLon: Double

    var matches: Int = 0

    var objectDidChange = ObservableObjectPublisher()
    private var cancellables = Set<AnyCancellable>()

    // radius of the circle in kilometers
    @Published var radius: Int {
        didSet {
            let recalculated = WeatherRegion(center: center, radius: radius)
            copyBoundaries(from: recalculated)
        }
    }

    // center of the circle
    var center: CLLocationCoordinate2D {
        get {
            let latitude = minLat + (maxLat - minLat) / 2
            let longitude = minLon + (maxLon - minLon) / 2

            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            let recalculated = WeatherRegion(center: newValue, radius: radius)
            copyBoundaries(from: recalculated)
        }
    }

    init(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double, radius: Int) {
        self.minLat = minLat
        self.maxLat = maxLat
        self.minLon = minLon
        self.maxLon = maxLon
        self.radius = radius
    }
    init(center: CLLocationCoordinate2D, radius: Int) {
        let top = center.locationAt(kilometers: Float(radius), direction: 0)
        let right = center.locationAt(kilometers: Float(radius), direction: 90)
        let bottom = center.locationAt(kilometers: Float(radius), direction: 180)
        let left = center.locationAt(kilometers: Float(radius), direction: 270)

        self.minLat = bottom.latitude
        self.maxLat = top.latitude
        self.minLon = left.longitude
        self.maxLon = right.longitude
        self.radius = radius
    }

    private func copyBoundaries(from: WeatherRegion) {
        self.minLat = from.minLat
        self.maxLat = from.maxLat
        self.minLon = from.minLon
        self.maxLon = from.maxLon

        objectDidChange.send()
    }

    static func isSet() -> Bool {
        return UserDefaults.cavok?.dictionary(forKey: "coordinates") as? [String: Double] != nil
    }

    static func load() -> WeatherRegion {
        if let coordinates = UserDefaults.cavok?.dictionary(forKey: "coordinates") as? [String: Double] {

            return WeatherRegion(
                minLat: coordinates["minLat"]!,
                maxLat: coordinates["maxLat"]!,
                minLon: coordinates["minLon"]!,
                maxLon: coordinates["maxLon"]!,
                radius: Int(coordinates["radius"]!)
            )
        } else {
            return WeatherRegion(center: LastLocation.load() ?? CLLocationCoordinate2DMake(50, 10),
                                 radius: 100)
        }
    }

    func save() {
        let coordinates = [
            "minLat": minLat,
            "maxLat": maxLat,
            "minLon": minLon,
            "maxLon": maxLon,
            "radius": Double(radius)
        ]

        print("Saving weather region \(coordinates)")

        let defaults = UserDefaults.cavok
        defaults?.set(coordinates, forKey: "coordinates")
        defaults?.synchronize()
    }

    func onChange(action: @escaping (WeatherRegion) -> Void) {
        objectDidChange
            .sink { action(self) }
            .store(in: &cancellables)
    }

    func inRange(latitude: Float, longitude: Float) -> Bool {
        let deg = center
        let location = CLLocation(latitude: deg.latitude, longitude: deg.longitude)
        let target = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))

        let distance = location.distance(from: target)
        return Int(distance) <= radius * 1000
    }
}
