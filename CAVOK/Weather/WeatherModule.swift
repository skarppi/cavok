//
//  WeatherModule.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 08.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class Ceiling: WeatherModule, MapModule {
    required init(delegate: MapDelegate) {
        super.init(delegate: delegate, observationValue: { $0.cloudHeight.value })
    }
}

class Visibility: WeatherModule, MapModule {
    required init(delegate: MapDelegate) {
        super.init(delegate: delegate, observationValue: { $0.visibility.value })
    }
}

final class Temperature: WeatherModule, MapModule {
    required init(delegate: MapDelegate) {
        super.init(delegate: delegate, observationValue: { ($0 as? Metar)?.temperature.value })
    }
}


open class WeatherModule {

    private let delegate: MapDelegate
    
    private let ramp: ColorRamp
    
    private let weatherServer = WeatherServer()
    
    private let observationValue: (Observation) -> Int?
    
    private let weatherLayer: WeatherLayer
    
    public init(delegate: MapDelegate, observationValue: @escaping (Observation) -> Int?) {
        self.delegate = delegate
        
        self.observationValue = observationValue
        
        let ramp = ColorRamp(module: type(of: self))
        self.ramp = ramp
        
        self.weatherLayer = WeatherLayer(mapView: delegate.mapView, ramp: ramp, observationValue: observationValue)
        
        let observations = weatherServer.observations(Metar.self)
        render(observations: observations)
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
        
        weatherServer.refreshObservations()
            .then(execute: render)
            .catch(execute: { error -> Void in
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
    
    private func render(observations: [Observation]) {
        let groups = ObservationGroup.group(observations: observations)
        self.delegate.setTimeslots(slots: groups.map { $0.slot })
        
        let frame = self.weatherLayer.render(groups: groups.map { $0.observations })
        render(frame: frame)
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
