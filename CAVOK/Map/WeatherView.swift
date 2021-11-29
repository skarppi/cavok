//
//  WeatherView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 24.11.2021.
//

import SwiftUI
import Combine
// import BottomSheet

public enum ObservationPositions: CGFloat, CaseIterable {
    case top = 0.975
    case middle = 0.4
    case bottom = 0.2
    case hidden = 0
}

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

    let updateTimestampsTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    @State private var observationPosition: ObservationPositions = .hidden

    @State private var selectedObservation: Observation?

    var body: some View {
        VStack(alignment: .trailing) {
            Picker("", selection: $selectedModule) {
                ForEach(Modules.available, id: \.self) { module in
                    Text(module.title).tag(module as Module?)
                }
            }
            .colorScheme(.light)
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
        .onChange(of: timeslots.selectedIndex) { frame in
            render(frame: frame)
        }
        .onReceive(updateTimestampsTimer) { _ in
            if timeslots.selectedIndex > 0 {
                render(frame: timeslots.selectedIndex)
            }
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
            bottomSheetPosition: .constant(TimeslotPositions.bottom),
            options: [
                .notResizeable,
                .noDragIndicator,
                .background(AnyView(EffectView(effect: UIBlurEffect(style: .systemThickMaterial))))
            ],
            headerContent: {
                PullToRefreshView(isLoading: $timeslots.isLoading) {
                    TimeslotDrawerView()
                        .environmentObject(timeslots)

                }
                // remove extra padding added by BottomSheet
                .padding(.top, -20)
                .frame(height: 100, alignment: .top)
                .refreshable {
                    timeslots.startSpinning()

                    Messages.show(text: "Refreshing observations...")

                    _ = weatherService.refreshObservations().done {
                        timeslots.stopSpinning()
                        load()
                    }.catch(Messages.show)
                }
            },
            mainContent: {}
        )
        .bottomSheet(
            bottomSheetPosition: $observationPosition,
            options: [
                .appleScrollBehavior,
                .swipeToDismiss
            ],
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

    private func render(frame: Int) {
        guard let weatherLayer = weatherLayer else {
            return
        }

        cleanMarkers()

        let observations = weatherLayer.go(frame: frame)

        let markers = observations.map { obs in
            return ObservationMarker(obs: obs)
        }

        if let key = markers.first,
           let components = mapApi.mapView.addScreenMarkers(markers, desc: nil) {
            mapApi.addComponents(key: key, value: components)
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

        print(status)
        timeslots.setStatus(text: "\(status) \(suffix)", color: ColorRamp.color(for: date))
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
            observationPosition = .bottom
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
