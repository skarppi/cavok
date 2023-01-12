//
//  WeatherView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 24.11.2021.
//

import SwiftUI
import Combine
import BottomSheet


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

    @State private var observationPosition: BottomSheetPosition = .hidden

    @State private var selectedObservation: Observation?

    @State private var loadingMessage: String?

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
            }).overlay(
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
                details(observation: observation)
            }
        }
        .bottomSheet(
            bottomSheetPosition: .constant(.dynamicBottom),
            switchablePositions: [.dynamicBottom],
            headerContent: {
                PullToRefreshView(loadingMessage: $loadingMessage) {
                    TimeslotDrawerView()
                        .environmentObject(timeslots)

                }
                // remove extra padding added by BottomSheet
                .frame(height: 100, alignment: .top)
                .refreshable {
                    loadingMessage = "Reloading weather"

                    do {
                        try await weatherService.refreshObservations()
                        loadingMessage = nil
                        load()
                    } catch {
                        Messages.show(error: error)
                    }
                }
            },
            mainContent: {}
        )
        .enableBackgroundBlur(true)
        .showDragIndicator(false)
        .isResizable(false)
        .bottomSheet(
            bottomSheetPosition: $observationPosition,
            switchablePositions: [.hidden, .dynamicBottom, .dynamicTop],
            headerContent: {
                if let observation = selectedObservation, let weatherLayer = weatherLayer {
                    ObservationHeaderView(presentation: weatherLayer.presentation,
                                          obs: observation) { () in
                        cleanDetails()
                    }
                }
            },
            mainContent: {
                if let observation = selectedObservation, let weatherLayer = weatherLayer {
                    let all = weatherService.observations(for: observation.station?.identifier ?? "")
                    ObservationDetailsView(presentation: weatherLayer.presentation,
                                           observations: all)
                }
            }
        )
        .enableAppleScrollBehavior(true)
        .enableSwipeToDismiss(true)
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

        let observations = weatherService.observations()

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

    private func cleanDetails() {
        observationPosition = .hidden
        mapApi.clearComponents(ofType: ObservationSelection.self)
        selectedObservation = nil
    }

    private func details(observation: Observation) {
        mapApi.clearComponents(ofType: ObservationSelection.self)

        selectedObservation = observation

        if observationPosition == .hidden {
            observationPosition = .dynamicBottom
        }

        let marker = ObservationSelection(obs: observation)
        if let components = mapApi.mapView.addScreenMarkers([marker], desc: nil) {
            mapApi.addComponents(key: marker, value: components)
        }
    }
}

struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases,
                id: \.self,
                content:
                    WeatherView(showWebView: { _ in
                        return true
                    }, showConfigView: {})
                        .preferredColorScheme
        )
    }
}
