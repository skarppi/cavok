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
    var minLat: Float
    var maxLat: Float
    var minLon: Float
    var maxLon: Float

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
    var center: MaplyCoordinate {
        get {
            let latitude = minLat + (maxLat - minLat) / 2
            let longitude = minLon + (maxLon - minLon) / 2

            return MaplyCoordinateMakeWithDegrees(longitude, latitude)
        }
        set {
            let recalculated = WeatherRegion(center: newValue, radius: radius)
            copyBoundaries(from: recalculated)
        }
    }

    var ll: MaplyCoordinate {
        return MaplyCoordinateMakeWithDegrees(minLon, minLat)
    }

    var ur: MaplyCoordinate {
        return MaplyCoordinateMakeWithDegrees(maxLon, maxLat)
    }

    init(minLat: Float, maxLat: Float, minLon: Float, maxLon: Float, radius: Int) {
        self.minLat = minLat
        self.maxLat = maxLat
        self.minLon = minLon
        self.maxLon = maxLon
        self.radius = radius
    }
    init(center: MaplyCoordinate, radius: Int) {
        let top = center.locationAt(kilometers: Float(radius), direction: 0)
        let right = center.locationAt(kilometers: Float(radius), direction: 90)
        let bottom = center.locationAt(kilometers: Float(radius), direction: 180)
        let left = center.locationAt(kilometers: Float(radius), direction: 270)

        self.minLat = bottom.deg.y
        self.maxLat = top.deg.y
        self.minLon = left.deg.x
        self.maxLon = right.deg.x
        self.radius = radius
    }

    private func copyBoundaries(from: WeatherRegion) {
        self.minLat = from.minLat
        self.maxLat = from.maxLat
        self.minLon = from.minLon
        self.maxLon = from.maxLon

        objectDidChange.send()
    }

    static func load() -> WeatherRegion? {
        let defaults = UserDefaults.standard
        if let coordinates = defaults.dictionary(forKey: "coordinates") as? [String: Float] {

            return WeatherRegion(
                minLat: coordinates["minLat"]!,
                maxLat: coordinates["maxLat"]!,
                minLon: coordinates["minLon"]!,
                maxLon: coordinates["maxLon"]!,
                radius: Int(coordinates["radius"]!)
            )
        } else {
            return nil
        }
    }

    func save() -> Bool {
        let coordinates = [
            "minLat": minLat,
            "maxLat": maxLat,
            "minLon": minLon,
            "maxLon": maxLon,
            "radius": Float(radius)
        ]

        print("Saving weather region \(coordinates)")

        let defaults = UserDefaults.standard
        defaults.set(coordinates, forKey: "coordinates")
        return defaults.synchronize()
    }

    func onChange(action: @escaping (WeatherRegion) -> Void) {
        objectDidChange
            .sink { action(self) }
            .store(in: &cancellables)
    }

    func inRange(latitude: Float, longitude: Float) -> Bool {
        let deg = center.deg
        let location = CLLocation(latitude: Double(deg.y), longitude: Double(deg.x))
        let target = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))

        let distance = location.distance(from: target)
        return Int(distance) <= radius * 1000
    }

    func bbox(padding kilometers: Float, offsetY: Float = 0) -> MaplyBoundingBox {
        let llPadded = ll.locationAt(kilometers: kilometers, direction: 225)
        let urPadded = ur.locationAt(kilometers: kilometers, direction: 45)

        return MaplyBoundingBox(ll: llPadded, ur: urPadded)
    }
}
