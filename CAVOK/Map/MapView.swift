//
//  MapView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 1.6.2021.
//

import SwiftUI
import Combine
import Pulley

struct MapView: View {
    @State private var selectedModule: Module? = Modules.available[0]

    @State private var showWebView = false

    @ObservedObject var locationManager = LocationManager.shared

    @ObservedObject var mapApi = MapApi.shared

    @State private var module: WeatherModule?

    @State private var orientation: PulleyDisplayMode = PulleyDisplayMode.automatic

    var body: some View {
        ZStack(alignment: .topLeading) {
            MapWrapper(mapApi: mapApi)
                .onAppear(perform: {
                    mapApi.mapReady.send()
                    locationManager.requestLocation()
                })
                .ignoresSafeArea()

            VStack(alignment: .trailing) {
                Picker("", selection: $selectedModule) {
                    ForEach(Modules.available, id: \.self) { module in
                        Text(module.title).tag(module as Module?)
                    }
                }
                // when pulley is on the left, move segmented control out of the way
                .padding(.leading, orientation != .drawer ? Pulley.shared.panelWidth + 20 : 10)
                .padding([.trailing, .top], 10)
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()

                if let module = selectedModule, module.legend.count > 0 {
                    LegendView(module: module)
                        .background(Color.white.opacity(0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                        .padding(.trailing, 10)
                }

                Button(
                    action: { module?.configure(open: true) },
                    label: {
                        Image(systemName: "gear")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .padding(5)
                }).overlay(
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(Color.blue, lineWidth: 1)
                )
                .padding(.trailing, 10)
            }
        }.onReceive(locationManager.$lastLocation.first()) { coordinate in
            userLocationChanged(coordinate: coordinate)
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            LastSession.save(
                center: mapApi.mapView.getPosition(),
                height: mapApi.mapView.getHeight())
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // request updated location
            locationManager.requestLocation()
        }.onReceive(selectedModule.publisher.first()) { newModule in
            moduleTypeChanged(newModule: newModule)
        }.onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            orientation = Pulley.shared.currentDisplayMode
        }.sheet(isPresented: $showWebView) {
            WebView()
        }
    }

    func moduleTypeChanged(newModule: Module) {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            return
        }

        let oldModule = self.module?.module

        guard newModule.key != .web else {
            showWebView = true
            selectedModule = oldModule
            return
        }
        guard !showWebView, oldModule != newModule else {
            return
        }

        module?.cleanup()
        module = WeatherModule(module: newModule)

        checkForFirstRun()
    }

    func userLocationChanged(coordinate: MaplyCoordinate?) {
        mapApi.clearComponents(ofType: UserMarker.self)

        if let coordinate = coordinate {
            let userLocation = UserMarker(coordinate: coordinate)
            if let objects = mapApi.mapView.addScreenMarkers([userLocation], desc: nil) {
                mapApi.addComponents(key: userLocation, value: objects)
            }

            let extents = mapApi.mapView.getCurrentExtents()
            if !extents.inside(coordinate) {
                mapApi.mapView.animate(toPosition: coordinate, time: 0.5)
            }
        }
    }

    fileprivate func checkForFirstRun() {
        if WeatherRegion.load() == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.module?.configure(open: true)
            })
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
