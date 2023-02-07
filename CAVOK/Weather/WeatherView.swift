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
    var showWebView: ((Bool) -> Bool)

    var showConfigView: (() -> Void)

    @State private var selectedModule: Module? = Modules.available[0]

    @State private var weatherLayer: WeatherLayer?

    @Environment(\.isPreview) var isPreview

    @StateObject var timeslots = TimeslotState()

    var mapApi = MapApi.shared

    let weatherService = WeatherServer()

    @State private var selectedObservation: Observation?

    @State private var loadingMessage: String?

    private let haptic = UIImpactFeedbackGenerator(style: .heavy)

    func observations() -> Observations? {
        if let observation = selectedObservation {
            do {
                return try weatherService.observations(for: observation.station?.identifier ?? "")
            } catch {
                Messages.show(error: error)
            }
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .trailing) {
            Picker("", selection: $selectedModule) {
                ForEach(Modules.available, id: \.self) { module in
                    Text(module.title).tag(module as Module?)
                }
            }
            .colorScheme(.light)
            .padding([.horizontal, .top], 10)
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()

            if let module = selectedModule, module.legend.count > 0 {
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
        .onReceive(timeslots.$selectedIndex) { frame in
            render(frame: frame)
        }
        .onReceive(selectedModule.publisher.first()) { newModule in
            moduleTypeChanged(newModule: newModule)
        }
        .onReceive(mapApi.didTapAt) { (_, object) in
            if let observation = object as? Observation {
                showDetails(observation)
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
            isPresented: .constant(selectedObservation != nil),
            onDismiss: {
                showDetails(nil)
            },
            headerContent: {
                if let observation = selectedObservation, let weatherLayer = weatherLayer {
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
        showConfigView()
    }

    func moduleTypeChanged(newModule: Module) {
        guard !isPreview else {
            return
        }

        let oldModule = weatherLayer?.presentation.module

        guard newModule.key != .web else {
            _ = showWebView(true)
            selectedModule = oldModule
            return
        }
        guard !showWebView(false), oldModule != newModule else {
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
            let observations = try weatherService.observations()

            let groups = observations.group()

            if let frame = groups.selectedFrame {
                timeslots.reset(slots: groups.timeslots, selected: frame)

                weatherLayer?.load(groups: groups, at: LastLocation.load()) { index, color in
                    self.timeslots.update(color: color, at: index)

                    if index == frame {
                        self.render(frame: frame)
                    }
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
        selectedObservation = observation

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
        WeatherView(showWebView: { _ in
            return true
        }, showConfigView: {})
    }
}
