//
//  MapWrapper.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 17.6.2021.
//

import SwiftUI
import UIKit
import Combine

struct MapWrapper: UIViewControllerRepresentable {

    var mapApi = MapApi.shared

    var components: [NSObject: MaplyComponentObject] = [:]

    @Environment(\.colorScheme) var colorScheme

    func makeUIViewController(context: Context) -> WhirlyGlobeViewController {
        mapApi.mapView = context.coordinator.mapView
        return context.coordinator.mapView
    }

    func getBaseMapUrl() -> String? {
        let scheme = colorScheme == .dark ? "dark" : "light"
        return UserDefaults.cavok?.string(forKey: "basemapURL\(scheme)")
    }

    func updateUIViewController(_ mapView: WhirlyGlobeViewController, context: Context) {
        if let loader = context.coordinator.backgroundLoader, let basemap = getBaseMapUrl() {
            TileJSONLayer.refresh(url: basemap, loader: loader)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WhirlyGlobeViewControllerDelegate {
        var mapView = WhirlyGlobeViewController()

        var backgroundLoader: MaplyQuadImageLoader?

        var parent: MapWrapper

        fileprivate var components: [NSObject: MaplyComponentObject] = [:]

        private var cancellables = Set<AnyCancellable>()

        @ObservedObject var locationManager = LocationManager.shared

        init(_ parent: MapWrapper) {
            self.parent = parent
            super.init()

            mapView.delegate = self

            if let basemap = parent.getBaseMapUrl() {
                backgroundLoader = TileJSONLayer.load(url: basemap, globeVC: mapView)
            }

            parent.mapApi.mapReady.sink { () in
                // camera position cannot be set before view has a parent

                self.mapView.keepNorthUp = true
                self.mapView.frameInterval = 1 // 60fps
                self.mapView.performanceOutput = false
                self.mapView.autoMoveToTap = false

                if let session = LastSession.load() {
                    self.mapView.height = session.height
                    self.mapView.setPosition(session.coordinate.maplyCoordinate)
                } else {
                    self.mapView.height = 0.7
                    self.mapView.setPosition(MaplyCoordinateMakeWithDegrees(10, 50))
                }
            }.store(in: &cancellables)
        }

        func globeViewController(_ view: WhirlyGlobeViewController, didTapAt coord: MaplyCoordinate) {
            parent.mapApi.didTapAt.send((coord, nil))
        }

        func globeViewController(_ view: WhirlyGlobeViewController,
                                 didSelect selected: NSObject,
                                 atLoc coord: MaplyCoordinate,
                                 onScreen screenPt: CGPoint) {
            if let marker = selected as? MaplyScreenMarker, let object = marker.userObject {
                parent.mapApi.didTapAt.send((coord, object))
            } else if let object = selected as? MaplyVectorObject {
                parent.mapApi.didTapAt.send((coord, object))
            }
        }
    }
}
