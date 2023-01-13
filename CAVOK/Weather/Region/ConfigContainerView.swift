//
//  ConfigContainerView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 24.11.2021.
//

import SwiftUI
import Combine
import BottomSheet

struct ConfigContainerView: View {

    var onClose: (() -> Void)

    @State private var bottomSheetPosition: BottomSheetPosition = .relative(0.4)

    @State private var region = WeatherRegion.load()

    let weatherService = WeatherServer()

    @State var links = Links.load()

    @ObservedObject var locationManager = LocationManager.shared

    @ObservedObject var mapApi = MapApi.shared

    @Environment(\.isPreview) var isPreview

    @State var loading: String?

    var cancellables = Set<AnyCancellable>()
    
    let bgColor: any ShapeStyle = Color(UIColor.secondarySystemBackground)

    var body: some View {
        ZStack {
        }.onAppear(perform: {
            region.onChange(action: refresh(region:))
            refresh(region: region)
        })
        .onReceive(locationManager.$lastLocation.first()) { coordinate in
            if let coord = coordinate {
                move(to: coord)
            }
        }
        .onReceive(mapApi.didTapAt) { (coord, _) in
            move(to: coord)
        }
        .bottomSheet(
            bottomSheetPosition: self.$bottomSheetPosition,
            switchablePositions: [.relative(0.125), .relative(0.4), .relativeTop(0.975)],
            headerContent: {
                if let loading = loading {
                    ProgressView(loading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    ConfigDrawerView(closedAction: { _ in
                        endRegionSelection()
                    }).environmentObject(region)
                }
            },
            mainContent: {
                LinksView(links: $links)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.top)
            }
        )
        .enableAppleScrollBehavior()
        .customBackground(bgColor)
    }

    private func move(to coord: MaplyCoordinate) {
        if let selection = mapApi.findComponent(ofType: RegionSelection.self) as? RegionSelection {
            selection.region.center = coord
            refresh(region: selection.region)
        }
    }

    private func refresh(region: WeatherRegion) {
        guard !isPreview else {
            return
        }

        mapApi.clearComponents(ofType: RegionSelection.self)

        let selection = RegionSelection(region: region)
        if let stickers = mapApi.mapView.addShapes([selection], desc: selection.desc) {
            mapApi.addComponents(key: selection, value: stickers)
        }

        // because drawer takes some space offset the region
        let offset = (
            km: Float(region.radius) / 5,
            dir: Float(180),
            padding: Float(region.radius) / 40
        )

        let center = region.center.locationAt(kilometers: offset.km, direction: offset.dir)

        let height = mapApi.mapView.findHeight(toViewBounds: region.bbox(padding: offset.padding), pos: center)
        mapApi.mapView.animate(toPosition: center, height: height, heading: 0, time: 0.5)

        showStations(at: region)
    }

    private func showStations(at region: WeatherRegion) {
        mapApi.clearComponents(ofType: StationMarker.self)

        Task {
            do {
                let stations = try await weatherService.queryStations(at: region)
                let markers = stations.map { station in StationMarker(station: station) }
                if let key = markers.first, let components = self.mapApi.mapView.addScreenMarkers(markers, desc: nil) {
                    self.mapApi.addComponents(key: key, value: components)
                }

                region.matches = stations.count
            } catch {
                Messages.show(error: error)
            }
        }
    }

    private func endRegionSelection() {
        bottomSheetPosition = .relative(0.125)

        mapApi.clearComponents(ofType: StationMarker.self)
        mapApi.clearComponents(ofType: RegionSelection.self)

        _ = Links.save(links)

        if region.save() {
            Task {
                do {
                    loading = "Reloading stations"
                    _ = try await weatherService.refreshStations()

                    loading = "Reloading weather"
                    try await weatherService.refreshObservations()
                } catch {
                    Messages.show(error: error)
                }

                onClose()
            }
        }
    }
}

struct ConfigContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigContainerView(onClose: {})
    }
}
