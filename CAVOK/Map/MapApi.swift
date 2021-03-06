//
//  MapApi.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 23.6.2021.
//

import Foundation
import Combine
import Pulley

public class MapApi: ObservableObject {

    static var shared = MapApi()

    var mapView: WhirlyGlobeViewController!

    fileprivate var components: [NSObject: MaplyComponentObject] = [:]

    var mapReady = PassthroughSubject<Void, Never>()

    var didTapAt = PassthroughSubject<(MaplyCoordinate, Any?), Never>()

//    func loaded(frame: Int?, legend: Legend) {
//        DispatchQueue.main.async {
//                self.buttonView.isHidden = false
//
//                if frame != nil {
//                    self.legendView.loaded(legend: legend)
//                    self.animateModuleType(show: true)
//                } else {
//                    self.resetRegion()
//                }
//        }
//    }

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
}
