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
        let frame = weatherLayer.render(observations: observations)
        render(frame: frame)
    }
    
    deinit {
        delegate.clearAnnotations(ofType: nil)
        delegate.clearComponents(ofType: ObservationMarker.self)
    }
    
    // MARK: - Region selection
    
    func didTapAt(coord: MaplyCoordinate) {
        if let selection = delegate.findComponent(ofType: RegionSelection.self) as? RegionSelection {
            selection.region.center = coord
            startRegionSelection(region: selection.region)
        }
    }
    
    private func startRegionSelection(region: WeatherRegion) {
        let annotation = RegionAnnotationView(region: region,
                                              closed: self.endRegionSelection,
                                              resized: self.showRegionSelection)
        delegate.mapView.addAnnotation(annotation, forPoint: region.center, offset: CGPoint.zero)
        
        showRegionSelection(region: region)
    }
    
    private func showRegionSelection(region: WeatherRegion) {
        delegate.clearComponents(ofType: RegionSelection.self)
        
        let selection = RegionSelection(region: region)
        if let stickers = delegate.mapView.addStickers([selection], desc: [kMaplyFade: 1.0]) {
            delegate.addComponents(key: selection, value: stickers)
        }
    }
    
    private func endRegionSelection(region: WeatherRegion? = nil) {
        delegate.clearComponents(ofType: RegionSelection.self)
        delegate.clearAnnotations(ofType: RegionAnnotationView.self)
        
        if region?.save() == true {
            self.refreshStations()
            self.weatherLayer.reposition()
        }
    }
    
    func configure(open: Bool, userLocation: MaplyCoordinate?) {
        if open {
            let region = WeatherRegion.load() ?? WeatherRegion(center: userLocation ?? delegate.mapView.getPosition(),
                                                               radius: 100)
            startRegionSelection(region: region)
        } else {
            endRegionSelection()
        }
    }
    
    // MARK: - Observations
    
    func refresh() {
        delegate.setStatus(text: "Refreshing observations...", color: .black)
        
        weatherServer.refreshObservations().then(execute: { observations -> Void in
            let frame = self.weatherLayer.render(observations: observations)
            self.render(frame: frame)
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
    
    func render(frame: Int?) {
        guard let frame = frame else {
            delegate.setStatus(text: "No data, click to reload.", color: ColorRamp.color(for: .IFR))
            return
        }
        
        delegate.clearAnnotations(ofType: nil)
        delegate.clearComponents(ofType: ObservationMarker.self)
        
        let observations = weatherLayer.go(frame: frame)
        
        let stations = observations.map({ obs in
            return ObservationMarker(obs: obs)
        })
        
        if let key = stations.first, let markers = delegate.mapView.addScreenMarkers(stations, desc: nil) {
            delegate.addComponents(key: key, value: markers)
        }
        
        renderTimestamp(min: observations.map { $0.datetime }.min()!)
        
    }
    
    private func renderTimestamp(min: Date) {
        let interval = min.timeIntervalSinceNow.negated()
        let minutes = Int(interval / 60)
        
        let formatter = DateComponentsFormatter()
        if minutes < 60*12  {
            formatter.allowedUnits = [.hour, .minute]
        } else {
            formatter.allowedUnits = [.day, .hour]
        }
        formatter.unitsStyle = .brief
        formatter.zeroFormattingBehavior = .dropLeading

        let status = formatter.string(from: interval)
        
        let condition: WeatherConditions = {
            if(minutes <= 30) {
                return .VFR
            } else if(minutes <= 90) {
                return .MVFR
            } else {
                return .IFR
            }
        }()
        
        delegate.setStatus(text: status, color: ColorRamp.color(for: condition))
    }
    
    func annotation(object: Any, parentFrame: CGRect) -> UIView? {
        if let observation = object as? Observation, let value = observationValue(observation) {
            return ObservationCalloutView(value: value, obs: observation, ramp: ramp, parentFrame: parentFrame)
        } else {
            return nil
        }
    }
}
