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
    
    private var ramp: ColorRamp! = nil
    
    private let weatherServer = WeatherServer()
    
    private let observationValue: (Observation) -> Int?
    
    private var weatherLayer: WeatherLayer! = nil
    
    public required init(delegate: MapDelegate) {
        self.delegate = delegate
        self.weatherLayer = nil
        self.observationValue = { (_) in nil }
        self.ramp = ColorRamp(module: self)
    }
    
    public init(delegate: MapDelegate, observationValue: @escaping (Observation) -> Int?) {
        self.delegate = delegate
        
        self.observationValue = observationValue
        
        self.ramp = ColorRamp(module: self)
        
        self.weatherLayer = WeatherLayer(delegate: self.delegate, ramp: ramp, observationValue: observationValue)
        
        let observations = weatherServer.observations(Metar.self)
        if !observations.isEmpty {
            let index = weatherLayer.render(observations: observations)
            render(index: index)
        }
    }
    
    deinit {
        delegate.clearAnnotations(ofType: nil)
        delegate.clearComponents(ofType: ObservationMarker.self)
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
        delegate.setStatus(text: "Refreshing observations...", color: .black)
        
        weatherServer.refreshObservations().then(execute: { observations -> Void in
            let frame = self.weatherLayer.render(observations: observations)
            self.render(index: frame)
        }).catch(execute: { error -> Void in
            self.delegate.setStatus(error: error)
        })
    }
    
    private func refreshStations() {
        delegate.setStatus(text: "Reloading stations...", color: .black)
        
        weatherServer.refreshStations().then { stations -> Void in
            self.delegate.setStatus(text: "Found \(stations.count) stations...", color: UIColor.black)
            self.refresh()
        }.catch { error -> Void in
            self.delegate.setStatus(error: error)
        }
    }
    
    func render(index: Int) {
        delegate.clearAnnotations(ofType: nil)
        delegate.clearComponents(ofType: ObservationMarker.self)
        
        let observations = weatherLayer.go(index: index)
        
        let stations = observations.map({ obs in
            return ObservationMarker(obs: obs)
        })
        
        if let key = stations.first, let markers = delegate.mapView.addScreenMarkers(stations, desc: nil) {
            delegate.addComponents(key: key, value: markers)
        }
        
        let times = observations.map { $0.datetime }
        renderTimestamp(min: times.min(), max: times.max())
        
    }
    
    private func renderTimestamp(min: Date!, max: Date!) {
        guard min != nil && max != nil else {
            delegate.setStatus(text: "No data, click to reload.", color: .red)
            return
        }
        
        let interval = min.timeIntervalSinceNow
        let minutes = Int(interval / -60)
        let hours = minutes / 60
        
        guard hours < 24 else {
            delegate.setStatus(text: "\(hours / 24) days old, click to reload", color: .red)
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        let from = dateFormatter.string(from: min)
        let to = dateFormatter.string(from: max)
        
        let status: String = {
            if from == to {
                return "\(from), \(minutes) min"
            } else {
                return "\(from) - \(to), \(minutes) min"
            }
        }()
        
        let condition: WeatherConditions = {
            if(minutes <= 30) {
                return .VFR
            } else if(minutes <= 60) {
                return .MVFR
            } else {
                return .IFR
            }
        }()
        
        delegate.setStatus(text: status, color: ColorRamp.color(forCondition: condition, alpha: 1))
    }
    
    func annotation(object: Any, parentFrame: CGRect) -> UIView? {
        if let observation = object as? Observation, let value = observationValue(observation) {
            return ObservationCalloutView(value: value, obs: observation, ramp: ramp, parentFrame: parentFrame)
        } else {
            return nil
        }
    }
}
