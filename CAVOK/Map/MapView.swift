//
//  MapView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 1.6.2021.
//

import SwiftUI
import Combine

struct MapView: View {

    @StateObject var navigation = NavigationManager()

    @ObservedObject var locationManager = LocationManager.shared

    @ObservedObject var mapApi = MapApi.shared

    @Environment(\.isPreview) var isPreview

    var body: some View {
        iPadSplitViewOrView(
            ZStack(alignment: .topLeading) {
                MapWrapper(mapApi: mapApi)
                    .onAppear {
                        mapApi.mapReady.send()
                        locationManager.requestLocation()
                        checkForFirstRun()
                    }
                    .ignoresSafeArea()

                if !navigation.showConfigView {
                    WeatherView()
                } else if !Self.isPad {
                    ConfigContainerView()
                }
            }
        )
        .onReceive(locationManager.$lastLocation) { coordinate in
            userLocationChanged(coordinate: coordinate)
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            LastSession.save(
                center: mapApi.mapView.getPosition().cl2d,
                height: mapApi.mapView.height)
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            locationManager.requestLocation()
        }
        .environmentObject(navigation)
    }

    func userLocationChanged(coordinate: CLLocationCoordinate2D?) {
        guard !isPreview else { return }

        mapApi.clearComponents(ofType: UserMarker.self)

        if let coordinate = coordinate?.maplyCoordinate {
            let userLocation = UserMarker(coordinate: coordinate)
            if let objects = mapApi.mapView.addScreenMarkers([userLocation], desc: nil) {
                mapApi.addComponents(key: userLocation, value: objects)
            }

            mapApi.animate(toPosition: coordinate)
        }
    }

    fileprivate func checkForFirstRun() {
        if !WeatherRegion.isSet() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                navigation.showConfigView = true
            })
        }
    }
}

extension MapView {
    @ViewBuilder
    func iPadSplitViewOrView<Content: View>(_ view: Content) -> some View {
        if Self.isPad {
            NavigationSplitView {
                if navigation.showConfigView {
                    ConfigContainerView()
                } else if navigation.selectedObservation != nil {
                    VStack {
                        ObservationHeaderView()

                        ObservationDetailsView()
                    }
                } else {
                    SidebarView()
                }
            } detail: {
                view
                    .navigationSplitViewStyle(.automatic)
            }
        } else {
            view
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
