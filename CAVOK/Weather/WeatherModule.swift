//
//  WeatherModule.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 08.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import SwiftUI
import Foundation
import PromiseKit
import Pulley
import Combine

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

    private weak var delegate: MapDelegate

    private let weatherService = WeatherServer()

    private let presentation: ObservationPresentation

    private let weatherLayer: WeatherLayer

    private var timeslots = TimeslotState()

    fileprivate weak var timer: Timer?

    private var cancellables = Set<AnyCancellable>()

    public init(delegate: MapDelegate, mapper: @escaping (Observation) -> (value: Int?, source: String?)) {
        self.delegate = delegate

        let ramp = ColorRamp(moduleType: type(of: self))
        presentation = ObservationPresentation(mapper: mapper, ramp: ramp)

        let region = WeatherRegion.load()

        weatherLayer = WeatherLayer(mapView: delegate.mapView, presentation: presentation, region: region)

        showTimeslotDrawer()

        timeslots.$selectedIndex
            .sink(receiveValue: render(frame:))
            .store(in: &cancellables)

        timeslots.refreshRequested
            .sink { self.refresh().catch(Messages.show)}
            .store(in: &cancellables)

        if region != nil {
            load(observations: weatherService.observations())
        }
    }

    func initTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
                if self.timeslots.selectedIndex > 0 {
                    self.render(frame: self.timeslots.selectedIndex)
                }
            }
        }
    }

    func cleanup() {
        delegate.clearComponents(ofType: ObservationMarker.self)
        cleanDetails()

        timer?.invalidate()
        timer = nil

        weatherLayer.clean()
    }

    // MARK: - Region selection

    func configure(open: Bool) {
        cleanup()

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
        if delegate.pulley.currentDisplayMode == .drawer {
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

        showTimeslotDrawer()
        timeslots.startSpinning()

        if let region = region, region.save() {
            weatherLayer.reposition(region: region)

            Messages.show(text: "Reloading stations...")

            weatherService.refreshStations().then { _ -> Promise<Void> in
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

    private func showTimeslotDrawer() {
        delegate.pulley.setDrawerPosition(position: .collapsed, animated: true)

        let timeline = TimeslotDrawerView {
            _ = self.refresh()
        }

        delegate.pulley.setDrawerContent(view: timeline.environmentObject(timeslots), sizes: PulleySizes(collapsed: 80, partial: nil, full: false), animated: false)
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
            timeslots.reset(slots: groups.timeslots, selected: frame)

            let userLocation = LastLocation.load()

            weatherLayer.load(groups: groups, at: userLocation) { index, color in
                self.timeslots.update(color: color, at: index)

                if index == frame {
                    self.render(frame: frame)

                    self.delegate.loaded(frame: frame, legend: self.presentation.ramp.legend())
                    self.initTimer()
                }
            }
        }
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

        if let tafs = observations as? [Taf],
           let latest = tafs.map({ $0.to }).max() {
            renderTimestamp(date: latest, suffix: "forecast")
        } else if let min = observations.map({ $0.datetime }).min() {
            renderTimestamp(date: min, suffix: "ago")
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

        timeslots.setStatus(text: "\(status) \(suffix)", color: ColorRamp.color(for: date))
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

        let all = weatherService.observations(for: observation.station?.identifier ?? "")

        let observationDrawer = ObservationDrawerView(presentation: presentation, obs: observation, observations: all) { () in
            self.cleanDetails()
            self.showTimeslotDrawer()
        }
        delegate.pulley.setDrawerContent(view: observationDrawer, sizes: observationDrawer.sizes, animated: false)
        delegate.pulley.setDrawerPosition(position: delegate.pulley.drawerPosition, animated: true)

        let marker = ObservationSelection(obs: observation)
        if let components = delegate.mapView.addScreenMarkers([marker], desc: nil) {
            delegate.addComponents(key: marker, value: components)
        }
    }
}
