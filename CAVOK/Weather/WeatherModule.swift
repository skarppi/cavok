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

class WeatherModule {
    let module: Module

    private let delegate = MapApi.shared

    private let weatherService = WeatherServer()

    let presentation: ObservationPresentation

    private let weatherLayer: WeatherLayer

    private var timeslots = TimeslotState()

    fileprivate weak var timer: Timer?

    private var cancellables = Set<AnyCancellable>()

    init(module: Module) {
        self.module = module

        presentation = ObservationPresentation(module: module)

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

        delegate.didTapAt.sink(receiveValue: { (coord, object) in
//                        guard self.buttonView.isHidden == false else {
//                            module?.didTapAt(coord: coord)
//                            return
//                        }

            if let details = object {
                self.details(object: details)
            } else {
                self.didTapAt(coord: coord)
            }
        }).store(in: &cancellables)
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

            region.onChange(action: moveRegionSelection(to:))

            Pulley.shared.setDrawerContent(
                view: ConfigDrawerView(closedAction: endRegionSelection).environmentObject(region),
                sizes: PulleySizes(collapsed: 275, partial: nil, full: true),
                animated: false)
            Pulley.shared.setDrawerPosition(position: .collapsed, animated: true)

            moveRegionSelection(to: region)
        } else {
            endRegionSelection()
        }
    }

    private func didTapAt(coord: MaplyCoordinate) {
        if let selection = delegate.findComponent(ofType: RegionSelection.self) as? RegionSelection {
            selection.region.center = coord
            moveRegionSelection(to: selection.region)
        }
    }

    private func moveRegionSelection(to region: WeatherRegion) {
        delegate.clearComponents(ofType: RegionSelection.self)

        let selection = RegionSelection(region: region)
        if let stickers = delegate.mapView.addShapes([selection], desc: selection.desc) {
            delegate.addComponents(key: selection, value: stickers)
        }

        // because drawer takes some space offset the region
        let offset: (km: Float, dir: Float, padding: Float)
        if Pulley.shared.currentDisplayMode == .drawer {
            offset = (km: Float(region.radius) / 5, dir: 180, padding: Float(region.radius) / 40)
        } else {
            offset = (km: Float(region.radius), dir: 270, padding: Float(region.radius) / 10)
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

            region.matches = stations.count
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
        Pulley.shared.setDrawerPosition(position: .collapsed, animated: true)

        let timeline = TimeslotDrawerView {
            _ = self.refresh()
        }

        Pulley.shared.setDrawerContent(view: timeline.environmentObject(timeslots),
                                         sizes: PulleySizes(collapsed: 80, partial: nil, full: false),
                                         animated: false)
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
                    self.initTimer()
                }
            }
        }
    }

    private func render(frame: Int) {
        delegate.clearComponents(ofType: ObservationMarker.self)

        let observations = weatherLayer.go(frame: frame)

        let markers = observations.map { obs in
            return ObservationMarker(obs: obs)
        }

        if let key = markers.first,
           let components = delegate.mapView.addScreenMarkers(markers, desc: nil) {
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

    private func details(object: Any) {
        guard let observation = object as? Observation else {
            return
        }

        cleanDetails()

        let all = weatherService.observations(for: observation.station?.identifier ?? "")

        let observationDrawer = ObservationDrawerView(presentation: presentation,
                                                      obs: observation,
                                                      observations: all) { () in
            self.cleanDetails()
            self.showTimeslotDrawer()
        }
        Pulley.shared.setDrawerContent(view: observationDrawer, sizes: observationDrawer.sizes, animated: true)

        let marker = ObservationSelection(obs: observation)
        if let components = delegate.mapView.addScreenMarkers([marker], desc: nil) {
            delegate.addComponents(key: marker, value: components)
        }
    }
}
