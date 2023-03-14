//
//  MapApi.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 23.6.2021.
//

import Foundation
import Combine

public class MapApi: ObservableObject {

    static var shared = MapApi()

    var mapView: WhirlyGlobeViewController!

    fileprivate var components: [NSObject: MaplyComponentObject] = [:]

    var mapReady = PassthroughSubject<Void, Never>()

    var didTapAt = PassthroughSubject<(MaplyCoordinate, Any?), Never>()

    func findComponent(ofType: NSObject.Type) -> NSObject? {
        return components.keys.filter { $0.isKind(of: ofType) }.first
    }

    func addComponents(key: NSObject, value: MaplyComponentObject) {
        components[key] = value
    }

    func clearComponents(ofType: NSObject.Type?) {
        if let ofType = ofType {
            let matching = components
                .filter { type(of: $0.key) == ofType }
                .compactMap { components.removeValue(forKey: $0.key) }
            mapView.remove(matching)
        } else {
            mapView.remove([MaplyComponentObject](components.values))
            components.removeAll()
        }
    }

    func animate(toPosition coordinate: MaplyCoordinate) {
        let extents = mapView.getCurrentExtents()
        if !extents.inside(coordinate) {
            let height = LastSession.load()?.height ?? 0.1

            mapView.animate(toPosition: coordinate, height: height, heading: 0, time: 0.5)
        }
    }
}
