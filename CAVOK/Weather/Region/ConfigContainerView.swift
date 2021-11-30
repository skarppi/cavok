//
//  ConfigContainerView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 24.11.2021.
//

import SwiftUI
import Combine
// import BottomSheet
import PromiseKit

struct ConfigContainerView: View {

    var onClose: (() -> Void)

    @State private var bottomSheetPosition: BottomSheetPosition = .middle

    @State private var region = WeatherRegion.load()

    let weatherService = WeatherServer()

    @State var links = Links.load()

    @ObservedObject var locationManager = LocationManager.shared

    @ObservedObject var mapApi = MapApi.shared

    @Environment(\.isPreview) var isPreview

    @State var loading: String?

    var cancellables = Set<AnyCancellable>()

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
            options: [
                .appleScrollBehavior
            ],
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
//                        .transition(.opacity)
//                        .animation(.easeInOut)
            }
        )
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
        let offset: (km: Float, dir: Float, padding: Float)
//        if Pulley.shared.currentDisplayMode == .drawer {
            offset = (km: Float(region.radius) / 5, dir: 180, padding: Float(region.radius) / 40)
//        } else {
//            offset = (km: Float(region.radius), dir: 270, padding: Float(region.radius) / 10)
//        }

        let center = region.center.locationAt(kilometers: offset.km, direction: offset.dir)

        let height = mapApi.mapView.findHeight(toViewBounds: region.bbox(padding: offset.padding), pos: center)
        mapApi.mapView.animate(toPosition: center, height: height, heading: 0, time: 0.5)

        showStations(at: region)
    }

    private func showStations(at region: WeatherRegion) {
        mapApi.clearComponents(ofType: StationMarker.self)
        weatherService.queryStations(at: region).done { stations in
            let markers = stations.map { station in StationMarker(station: station) }
            if let key = markers.first, let components = self.mapApi.mapView.addScreenMarkers(markers, desc: nil) {
                self.mapApi.addComponents(key: key, value: components)
            }

            region.matches = stations.count
        }.catch(Messages.show)
    }

    private func endRegionSelection() {
        mapApi.clearComponents(ofType: StationMarker.self)
        mapApi.clearComponents(ofType: RegionSelection.self)

        _ = Links.save(links)

        if region.save() {
            loading = "Reloading stations"

            weatherService.refreshStations().then { _ -> Promise<Void> in
                loading = "Reloading weather"
                return weatherService.refreshObservations()
            }.catch { err in
                Messages.show(error: err)
            }.finally {
                onClose()
            }
        }
    }
}

struct ConfigContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases,
                id: \.self,
                content:
                    ConfigContainerView(onClose: {}).preferredColorScheme
        )
    }
}