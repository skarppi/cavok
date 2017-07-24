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
        super.init(delegate: delegate, observationValue: { ($0 as? Metar)?.spreadCeiling() })
    }
}


open class WeatherModule {

    private let delegate: MapDelegate
    
    private let ramp: ColorRamp
    
    private let weatherService = WeatherServer()
    
    private let observationValue: (Observation) -> Int?
    
    private let weatherLayer: WeatherLayer
    
    private let timeslotDrawer: TimeslotDrawerController!
    
    public init(delegate: MapDelegate, observationValue: @escaping (Observation) -> Int?) {
        self.delegate = delegate
        
        self.observationValue = observationValue
        
        let ramp = ColorRamp(module: type(of: self))
        self.ramp = ramp
        
        let region = WeatherRegion.load()
        
        self.weatherLayer = WeatherLayer(mapView: delegate.mapView, ramp: ramp, observationValue: observationValue, region: region)
    
        timeslotDrawer = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "drawer") as! TimeslotDrawerController
        delegate.pulley.setDrawerContentViewController(controller: timeslotDrawer)
        timeslotDrawer.setModule(module: self as? MapModule)
        
        if region != nil {
            load(observations: weatherService.observations())
        }
        
    }
    
    deinit {
        delegate.clearAnnotations(ofType: nil)
        delegate.clearComponents(ofType: ObservationMarker.self)
    }
    
    // MARK: - Region selection
    
    func didTapAt(coord: MaplyCoordinate) {
        if let selection = delegate.findComponent(ofType: RegionSelection.self) as? RegionSelection {
            selection.region.center = coord
            startRegionSelection(at: selection.region)
        }
    }
    
    private func startRegionSelection(at region: WeatherRegion) {
        let regionDrawer = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "regionDrawer") as! RegionDrawerController
        regionDrawer.setup(region: region, closed: endRegionSelection, resized: showRegionSelection)
        delegate.pulley.setDrawerContentViewController(controller: regionDrawer)
        delegate.pulley.setDrawerPosition(position: .partiallyRevealed, animated: true)
    }
    
    private func showRegionSelection(at region: WeatherRegion) {
        delegate.clearComponents(ofType: RegionSelection.self)
        
        let selection = RegionSelection(region: region)
        if let stickers = delegate.mapView.addStickers([selection], desc: [kMaplyFade: 1.0]) {
            delegate.addComponents(key: selection, value: stickers)
        }
        
        showStations(at: region)
    }
    
    private func showStations(at region: WeatherRegion) {
        delegate.clearComponents(ofType: StationMarker.self)
        weatherService.queryStations(at: region).then { stations -> Void in
            let markers = stations.map { station in StationMarker(station: station) }
            if let key = markers.first, let components = self.delegate.mapView.addScreenMarkers(markers, desc: nil) {
                self.delegate.addComponents(key: key, value: components)
            }
            
            if let drawer = self.delegate.pulley.drawerContentViewController as? RegionDrawerController {
                drawer.status(text: "Found \(stations.count) stations")
            }
            
            }.catch(execute: Messages.show)
    }
    
    private func endRegionSelection(at region: WeatherRegion? = nil) {
        delegate.clearComponents(ofType: StationMarker.self)
        delegate.clearComponents(ofType: RegionSelection.self)
        
        delegate.pulley.setDrawerContentViewController(controller: timeslotDrawer)
        delegate.pulley.setDrawerPosition(position: .closed, animated: true)
        
        if region?.save() == true {
            weatherLayer.reposition(region: region!)
            
            refreshStations()
        } else {
            load(observations: weatherService.observations())
        }
    }
    
    func configure(open: Bool) {
        delegate.clearComponents(ofType: ObservationMarker.self)
        self.weatherLayer.clean()
        
        if open {
            let region = WeatherRegion.load() ??
                WeatherRegion(center: LastLocation.load() ?? delegate.mapView.getPosition(),
                              radius: 100)
            startRegionSelection(at: region)
        } else {
            endRegionSelection()
        }
    }
    
    // MARK: - Observations
    
    func refresh() {
        Messages.show(text: "Refreshing observations...")
        
        weatherService.refreshObservations()
            .then(execute: load)
            .catch(execute: Messages.show)
    }
    
    private func refreshStations() {
        Messages.show(text: "Reloading stations...")
        
        weatherService.refreshStations().then { stations -> Void in
            self.refresh()
        }.catch(execute: Messages.show)
    }
    
    private func load(observations: Observations) {
        Messages.hide()
        
        let groups = observations.group()
        
        if let frame = groups.selectedFrame {
            timeslotDrawer.loaded(frame: frame, timeslots: groups.timeslots)
            delegate.pulley.setDrawerPosition(position: .collapsed, animated: true)
            
            weatherLayer.load(groups: groups)
        }
        
        delegate.loaded(frame: groups.selectedFrame, timeslots: groups.timeslots, legend: ramp.legend())
        render(frame: groups.selectedFrame)
    }
    
    func render(frame: Int?) {
        guard let frame = frame else {
            Messages.show(text: "No data")
            return
        }
        
        delegate.clearAnnotations(ofType: nil)
        delegate.clearComponents(ofType: ObservationMarker.self)
        
        let observations = weatherLayer.go(frame: frame)
        
        let markers = observations.map { obs in
            return ObservationMarker(obs: obs)
        }
        
        if let key = markers.first, let components = delegate.mapView.addScreenMarkers(markers, desc: nil) {
            delegate.addComponents(key: key, value: components)
        }
        
        if let tafs = observations as? [Taf] {
            renderTimestamp(date: tafs.map { $0.to }.max()!, suffix: "forecast")
        } else {
            renderTimestamp(date: observations.map { $0.datetime }.min()!, suffix: "ago")
        }
    }
    
    private func renderTimestamp(date: Date, suffix: String) {
        let seconds = abs(date.timeIntervalSinceNow)
        
        let formatter = DateComponentsFormatter()
        if seconds < 3600*6 {
            formatter.allowedUnits = [.hour, .minute]
        } else {
            formatter.allowedUnits = [.day, .hour]
        }
        formatter.unitsStyle = .brief
        formatter.zeroFormattingBehavior = .dropLeading

        let status = formatter.string(from: seconds)!
        
        timeslotDrawer.setStatus(text: "\(status) \(suffix)", color: ColorRamp.color(for: date))
    }
    
    func annotation(object: Any, parentFrame: CGRect) -> UIView? {
        if let observation = object as? Observation, let value = observationValue(observation) {
            return ObservationCalloutView(value: value, obs: observation, ramp: ramp, parentFrame: parentFrame)
        } else {
            return nil
        }
    }
}
