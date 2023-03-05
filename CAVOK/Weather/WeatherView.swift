//
//  WeatherView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 24.11.2021.
//

import SwiftUI
import Combine

struct TimeslotPositions: CaseIterable, RawRepresentable {
    init(rawValue: CGFloat) {
        let maxAvailableHeight = UIScreen.main.bounds.size.height
        self.rawValue = rawValue / maxAvailableHeight
    }

    var rawValue: CGFloat

    static let hidden = TimeslotPositions(rawValue: 0)
    static let bottom = TimeslotPositions(rawValue: 140)

    static var allCases: [TimeslotPositions] = [.hidden, .bottom]

    typealias RawValue = CGFloat
}

struct WeatherView: View {
    @EnvironmentObject var navigation: NavigationManager

    @State private var weatherLayer: WeatherLayer?

    @Environment(\.isPreview) var isPreview

    @StateObject var timeslots = TimeslotState()

    var mapApi = MapApi.shared

    let weatherService = WeatherServer()

    @State private var loadingMessage: String?

    private let haptic = UIImpactFeedbackGenerator(style: .heavy)

    func observations() -> Observations? {
        if let observation = navigation.selectedObservation {
            do {
                return try weatherService.query.observations(for: observation.station?.identifier ?? "")
            } catch {
                Messages.show(error: error)
            }
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .trailing) {
            Picker("", selection: $navigation.selectedModule) {
                ForEach(Modules.available, id: \.self) { module in
                    Text(module.title).tag(module as Module?)
                }
            }
            .colorScheme(.light)
            .padding([.horizontal, .top], 10)
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()

            if let module = navigation.selectedModule, module.legend.count > 0 {
                LegendView(module: module)
                    .padding(.trailing, 10)
            }

            Button(
                action: configure,
                label: {
                    Image(systemName: "gear")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .padding(5)
                }
            ).overlay(
                RoundedRectangle(cornerRadius: 50)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .padding(.trailing, 10)

            Spacer()
        }
        .onReceive(timeslots.$selectedFrame) { frame in
            render(frame: frame)
        }
        .onReceive(navigation.selectedModule.publisher.first()) { newModule in
            moduleTypeChanged(newModule: newModule)
        }
        .onReceive(navigation.$selectedObservation) { observation in
            showDetails(observation)
        }
        .onReceive(mapApi.didTapAt) { (_, object) in
            if let observation = object as? Observation {
                navigation.selectedObservation = observation
            }
        }
        .overlay(alignment: .bottom) {
            PullToRefreshView(loadingMessage: $loadingMessage) {
                TimeslotDrawerView()
                    .environmentObject(timeslots)
            }
            .frame(height: 100, alignment: .top)
            .background(.regularMaterial)
            .refreshable {
                loadingMessage = "Reloading weather"
                haptic.impactOccurred()

                do {
                    try await weatherService.refreshObservations()
                    loadingMessage = nil
                    load()
                } catch {
                    Messages.show(error: error)
                }
            }
        }
        .bottomSheet(
            isPresented: .constant(navigation.selectedObservation != nil && Self.isPhone),
            onDismiss: {
                showDetails(nil)
            },
            headerContent: {
                if let observation = navigation.selectedObservation, let weatherLayer = weatherLayer {
                    ObservationHeaderView(presentation: weatherLayer.presentation,
                                          obs: observation) { () in
                        showDetails(nil)
                    }
                }
            },
            mainContent: {

                if let weatherLayer = weatherLayer, let observations = observations() {
                    ObservationDetailsView(presentation: weatherLayer.presentation,
                                           observations: observations)
                }
            }
        ).presentationDetents(
            [.dynamicHeader, .medium, .large],
            selection: .constant(.dynamicHeader)
        )
    }

    private func cleanMarkers() {
        mapApi.clearComponents(ofType: ObservationMarker.self)
    }

    func configure() {
        cleanMarkers()
        navigation.showConfigView = true
    }

    func moduleTypeChanged(newModule: Module) {
        guard !isPreview else {
            return
        }

        let oldModule = weatherLayer?.presentation.modules.first

        guard newModule.key != .web else {
            navigation.showWebView = true
            navigation.selectedModule = oldModule
            return
        }
        guard !navigation.showWebView, oldModule != newModule else {
            return
        }

        let presentation = ObservationPresentation(module: newModule)

        weatherLayer?.clean()
        weatherLayer = WeatherLayer(mapView: mapApi.mapView, presentation: presentation)

        load()
    }

    private func load() {
        Messages.hide()

        do {
            let observations = try weatherService.query.observations()

            timeslots.reset(observations: observations)

            weatherLayer?.load(slots: timeslots.slots,
                               selected: timeslots.selectedFrame,
                               at: LastLocation.load()) { index, color in
                self.timeslots.update(color: color, at: index)

                if index == timeslots.selectedFrame {
                    self.render(frame: timeslots.selectedFrame)
                }
            }
        } catch {
            Messages.show(error: error)
        }
    }

    private func render(frame: Int?) {
        guard !isPreview else {
            return
        }

        cleanMarkers()

        guard let weatherLayer = weatherLayer, let frame = frame else {
            return
        }

        let observations = weatherLayer.go(frame: frame)

        let markers = observations.map { obs in
            return ObservationMarker(obs: obs)
        }

        if let key = markers.first,
            let components = mapApi.mapView.addScreenMarkers(markers, desc: nil) {
            mapApi.addComponents(key: key, value: components)
        }
    }

    private func showDetails(_ observation: Observation?) {
        mapApi.clearComponents(ofType: ObservationSelection.self)

        if let observation = observation {
            let marker = ObservationSelection(obs: observation)
            if let components = mapApi.mapView.addScreenMarkers([marker], desc: nil) {
                mapApi.addComponents(key: marker, value: components)
            }
        }
    }
}

struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherView()
            .environmentObject(NavigationManager())
    }
}
