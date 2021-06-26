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
    var pulley: PulleyViewController

    @State private var selectedModule: String? = Modules.availableTitles()[0]

    @State private var showWebView = false

    @ObservedObject var locationManager = LocationManager.shared

    @ObservedObject var mapApi: MapApi

    @State private var module: MapModule?

    @State private var orientation: PulleyDisplayMode = PulleyDisplayMode.automatic

    init(pulley: PulleyViewController) {
        self.pulley = pulley
        mapApi = MapApi(pulley: pulley)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            MapWrapper(mapApi: mapApi)
                .onAppear(perform: {

                    mapApi.mapReady.send()
                    locationManager.requestLocation()
                })
                .ignoresSafeArea()

            Picker("", selection: $selectedModule) {
                ForEach(Modules.availableTitles(), id: \.self) {
                    Text($0).tag($0 as String?)
                }
            }
            // when pulley is on the left, move segmented control out of the way
            .padding(.leading, orientation != .drawer ? pulley.panelWidth + 20 : 10)
            .padding([.trailing, .top], 10)
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
            .onAppear(perform: {
                print(pulley.additionalSafeAreaInsets)
            })
        }.onReceive(locationManager.$lastLocation.first()) { coordinate in
            userLocationChanged(coordinate: coordinate)
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            LastSession.save(
                center: mapApi.mapView.getPosition(),
                height: mapApi.mapView.getHeight())
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // request updated location
            locationManager.requestLocation()
        }.onReceive(selectedModule.publisher.first()) { title in
            moduleTypeChanged(title: title)
        }.onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            orientation = pulley.currentDisplayMode
        }.sheet(isPresented: $showWebView) {
            WebView()
        }
    }

    func moduleTypeChanged(title: String) {
        let oldModule = module.flatMap {
            Modules.title(of: type(of: $0))
        }

        guard title != "Web" else {
            showWebView = true
            selectedModule = oldModule
            return
        }
        guard !showWebView, oldModule != title else {
            return
        }

        module?.cleanup()
        module = Modules.loadModule(title: title, delegate: mapApi)

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
        MapView(pulley: PulleyViewController(contentViewController: UIViewController(), drawerViewController: UIViewController()))
    }
}
