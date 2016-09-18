//
//  WeatherModule.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 08.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class Ceiling: WeatherModule {
    required init(delegate: MapDelegate) {
        super.init(delegate: delegate, observationValue: { $0.cloudHeight.value })
    }
}

class Visibility: WeatherModule {
    required init(delegate: MapDelegate) {
        super.init(delegate: delegate, observationValue: { $0.visibility.value })
    }
}

final class Temperature: WeatherModule {
    required init(delegate: MapDelegate) {
        super.init(delegate: delegate, observationValue: { ($0 as? Metar)?.temperature.value })
    }
}


open class WeatherModule: MapModule {

    private let delegate: MapDelegate
    
    private let weatherServer = WeatherServer()
    
    private var weatherLayer: WeatherLayer! = nil
    
    public required init(delegate: MapDelegate) {
        self.delegate = delegate
        self.weatherLayer = nil
    }
    
    public init(delegate: MapDelegate, observationValue: @escaping (Observation) -> Int?) {
        self.delegate = delegate
        
        self.weatherLayer = WeatherLayer(module: self, delegate: self.delegate, observationValue: observationValue)
        
        let observations = weatherServer.observations(Metar.self)
        if !observations.isEmpty {
            weatherLayer.render(observations: observations)
        }
    }
    
    func didTapAt(coord: MaplyCoordinate) {
        if let selection = delegate.findComponent(ofType: RegionSelection.self) as? RegionSelection {
            selection.region.center = coord
            startRegionSelection(region: selection.region)
        }
    }
    
    private func startRegionSelection(region: WeatherRegion) {
        self.delegate.clearComponents(ofType: RegionSelection.self)
        self.delegate.clearAnnotations(ofType: RegionAnnotationView.self)

        let annotation = RegionAnnotationView(region: region, closed: { region in
            self.delegate.clearComponents(ofType: RegionSelection.self)
            self.delegate.clearAnnotations(ofType: RegionAnnotationView.self)
            if region.save() {
                self.refreshStations()
                self.weatherLayer.reposition()
            }
        }, resized: { region in
            self.startRegionSelection(region: region)
        })
        
        let selection = RegionSelection(region: region)
        
        if let stickers = self.delegate.mapView.addStickers([selection], desc: [kMaplyFade: 1.0]) {
            self.delegate.addComponents(key: selection, value: stickers)
        }
        self.delegate.mapView.addAnnotation(annotation, forPoint: region.center, offset: CGPoint.zero)
    }
    
    func configure(userLocation: MaplyCoordinate?) {
        if let region = WeatherRegion.load() {
            if userLocation == nil {
                startRegionSelection(region: region)
            }
        } else {
            let center = userLocation ?? delegate.mapView.getPosition()
            startRegionSelection(region: WeatherRegion(center: center, radius: 100))
        }
    }
    
    func refresh() {
        weatherServer.refreshObservations().then(execute: { observations -> Void in
            self.weatherLayer.render(observations: observations)
            self.delegate.setStatus(text: "\(observations.count)", color: UIColor.red)
        }).catch(execute: { error -> Void in
            self.delegate.setStatus(error: error)
        })
    }
    
    fileprivate func refreshStations() {
        delegate.setStatus(text: "Reloading stations...", color: UIColor.black)
        
        weatherServer.refreshStations().then { stations -> Void in
            self.refresh()
        }.catch { error -> Void in
            self.delegate.setStatus(error: error)
        }
    }
}
