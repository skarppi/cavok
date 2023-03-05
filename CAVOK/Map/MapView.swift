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
        NavigationSplitView {
            if navigation.showConfigView && Self.isPad {
                ConfigContainerView()
                    .environmentObject(navigation)
            } else {
                SidebarView()
                    .environmentObject(navigation)
            }
        } detail: {
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
                        .environmentObject(navigation)
                } else if !Self.isPad {
                    ConfigContainerView()
                        .environmentObject(navigation)
                }
            }
            .navigationSplitViewStyle(.automatic)
        }.onReceive(locationManager.$lastLocation.first()) { coordinate in
            userLocationChanged(coordinate: coordinate)
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            LastSession.save(
                center: mapApi.mapView.getPosition(),
                height: mapApi.mapView.height)
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            locationManager.requestLocation()
        }.bottomSheet(
            isPresented: $navigation.showWebView,
            headerContent: {},
            mainContent: {
                WebView()
            }
        )
    }

    func userLocationChanged(coordinate: CLLocationCoordinate2D?) {
        guard !isPreview else { return }

        mapApi.clearComponents(ofType: UserMarker.self)

        if let coordinate = coordinate?.maplyCoordinate {
            let userLocation = UserMarker(coordinate: coordinate)
            if let objects = mapApi.mapView.addScreenMarkers([userLocation], desc: nil) {
                mapApi.addComponents(key: userLocation, value: objects)
            }

            let extents = mapApi.mapView.getCurrentExtents()
            if !extents.inside(coordinate) {
                let height = LastSession.load()?.height ?? 0.1

                mapApi.mapView.animate(toPosition: coordinate, height: height, heading: 0, time: 0.5)
            }
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

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
