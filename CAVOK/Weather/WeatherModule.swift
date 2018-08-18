//
//  WeatherModule.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 08.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import PromiseKit
import Pulley

class Ceiling: WeatherModule, MapModule {
    required init(delegate: MapDelegate) {
        super.init(delegate: delegate, mapper: { ($0.cloudHeight.value, $0.clouds) })
    }
}

class Visibility: WeatherModule, MapModule {
    required init(delegate: MapDelegate) {
        super.init(delegate: delegate, mapper: { ($0.visibility.value, $0.visibilityGroup) })
    }
}

final class Temperature: WeatherModule, MapModule {
    required init(delegate: MapDelegate) {
        super.init(delegate: delegate, mapper: {
            let metar = $0 as? Metar
            return (metar?.spreadCeiling(), metar?.temperatureGroup)
        })
    }
}


open class WeatherModule {

    private let delegate: MapDelegate
    
    private let weatherService = WeatherServer()
    
    private let presentation: ObservationPresentation
    
    private let weatherLayer: WeatherLayer
    
    private let timeslotDrawer: TimeslotDrawerController!
    
    fileprivate weak var timer: Timer?
    
    public init(delegate: MapDelegate, mapper: @escaping (Observation) -> (value: Int?, source: String?)) {
        self.delegate = delegate
        
        let ramp = ColorRamp(moduleType: type(of: self))
        self.presentation = ObservationPresentation(mapper: mapper, ramp: ramp)
        
        let region = WeatherRegion.load()
        
        self.weatherLayer = WeatherLayer(mapView: delegate.mapView, presentation: presentation, region: region)
    
        timeslotDrawer = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "drawer") as! TimeslotDrawerController
        timeslotDrawer.setModule(module: self as? MapModule)
        showLoadingDrawer()
        
        if region != nil {
            load(observations: weatherService.observations())
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            let timeslotSelected = self.timeslotDrawer.timeslots.selectedSegmentIndex != -1
            let notConfiguring = self.delegate.pulley.drawerContentViewController as? ConfigDrawerController == nil
            
            if timeslotSelected && notConfiguring {
                self.render(frame: self.timeslotDrawer.timeslots.selectedSegmentIndex)
            }
        }
    }
    
    func cleanup() {
        delegate.clearComponents(ofType: ObservationMarker.self)
        cleanDetails()
        
        timer?.invalidate()
    }
    
    // MARK: - Region selection
    
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
    
    func didTapAt(coord: MaplyCoordinate) {
        if let selection = delegate.findComponent(ofType: RegionSelection.self) as? RegionSelection {
            selection.region.center = coord
            startRegionSelection(at: selection.region)
        }
    }
    
    private func startRegionSelection(at region: WeatherRegion) {
        let drawer = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "configDrawer") as! ConfigDrawerController
        drawer.setup(region: region, closed: endRegionSelection, resized: moveRegionSelection)
        delegate.pulley.setDrawerContentViewController(controller: drawer)
        delegate.pulley.setDrawerPosition(position: .collapsed, animated: true)
    }
    
    private func moveRegionSelection(at region: WeatherRegion) {
        delegate.clearComponents(ofType: RegionSelection.self)
        
        let selection = RegionSelection(region: region)
        if let stickers = delegate.mapView.addShapes([selection], desc: selection.desc) {
            delegate.addComponents(key: selection, value: stickers)
        }
        
        // because drawer takes some space offset the region
        let offset: (km: Float, dir: Float, padding: Float)
        if delegate.pulley.currentDisplayMode == .bottomDrawer {
            offset = (km: region.radius / 5, dir: 180, padding: region.radius / 40)
        } else {
            offset = (km: region.radius, dir: 270, padding: region.radius / 10)
        }
        
        let center = region.center.locationAt(kilometers: offset.km, direction: offset.dir)
        
        let height = delegate.mapView.findHeight(toViewBounds: region.bbox(padding: offset.padding), pos: center)
        delegate.mapView.animate(toPosition: center, height: height, heading: 0, time: 0.5)
        
        showStations(at: region)
    }
    
    private func showStations(at region: WeatherRegion) {
        delegate.clearComponents(ofType: StationMarker.self)
        weatherService.queryStations(at: region).done { stations in
            let markers = stations.map { station in StationMarker(station: station) }
            if let key = markers.first, let components = self.delegate.mapView.addScreenMarkers(markers, desc: nil) {
                self.delegate.addComponents(key: key, value: components)
            }
            
            if let drawer = self.delegate.pulley.drawerContentViewController as? ConfigDrawerController {
                drawer.status(text: "Found \(stations.count) stations")
            }
            
        }.catch(Messages.show)
    }
    
    private func endRegionSelection(at region: WeatherRegion? = nil) {
        delegate.clearComponents(ofType: StationMarker.self)
        delegate.clearComponents(ofType: RegionSelection.self)
        
        showLoadingDrawer()
        
        if let region = region, region.save() {
            weatherLayer.reposition(region: region)
            
            Messages.show(text: "Reloading stations...")
            
            weatherService.refreshStations().then { stations -> Promise<Void> in
                self.refresh()
            }.catch { err in
                Messages.show(error: err)
                self.load(observations: self.weatherService.observations())
            }
        } else {
            load(observations: weatherService.observations())
        }
    }
    
    // MARK: - Drawers
    
    private func showLoadingDrawer() {
        delegate.pulley.setDrawerPosition(position: .partiallyRevealed, animated: true)
        delegate.pulley.setDrawerContentViewController(controller: timeslotDrawer)
        timeslotDrawer.startSpinning()
    }

    private func showTimeslotDrawer() {
        delegate.pulley.setDrawerPosition(position: .partiallyRevealed, animated: true)
        delegate.pulley.setDrawerContentViewController(controller: timeslotDrawer)
    }
    
    // MARK: - Observations
    
    func refresh() -> Promise<Void> {
        Messages.show(text: "Refreshing observations...")
        
        return weatherService.refreshObservations().map(load)
    }
    
    private func load(observations: Observations) {
        Messages.hide()
        
        let groups = observations.group()
        
        if let frame = groups.selectedFrame {
            timeslotDrawer.reset(timeslots: groups.timeslots, selected: frame)
            
            let userLocation = LastLocation.load()
            
            weatherLayer.load(groups: groups, at: userLocation, loaded: { frame, color in
                self.timeslotDrawer.update(color: color, at: frame)
            })
            
            delegate.pulley.setDrawerPosition(position: .partiallyRevealed, animated: true)
            
            render(frame: frame)
        }
        
        delegate.loaded(frame: groups.selectedFrame, legend: presentation.ramp.legend())
    }
    
    func render(frame: Int) {
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
    
    private func cleanDetails() {
        delegate.clearComponents(ofType: ObservationSelection.self)
    }
    
    private func quitDetails() {
        cleanDetails()
        showTimeslotDrawer()
    }
    
    func details(object: Any, parentFrame: CGRect) {
        guard let observation = object as? Observation else {
            return
        }
        
        cleanDetails()
        
        let observationDrawer = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "observationDrawer") as! ObservationDrawerController
        delegate.pulley.setDrawerContentViewController(controller: observationDrawer, animated: false)
        
        let all = weatherService.observations(for: observation.station?.identifier ?? "")
        observationDrawer.setup(closed: quitDetails, presentation: presentation, obs: observation, observations: all)
    
        delegate.pulley.setNeedsSupportedDrawerPositionsUpdate()
        delegate.pulley.setDrawerPosition(position: delegate.pulley.drawerPosition, animated: true)
        
        let marker = ObservationSelection(obs: observation)
        if let components = delegate.mapView.addScreenMarkers([marker], desc: nil) {
            delegate.addComponents(key: marker, value: components)
        }
    }
}
