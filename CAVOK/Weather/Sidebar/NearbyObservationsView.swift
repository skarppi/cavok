//
//  NearbyObservationsView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 5.3.2023.
//

import SwiftUI

struct NearbyObservationsView: View {
    @EnvironmentObject var navigation: NavigationManager

    @State var observations: [WithDistance<Observation>] = []

    func fetchObservations() -> [WithDistance<Observation>] {
        if let location = LastLocation.load() {
            do {
                return try WeatherServer.query.nearby(location: location)
            } catch {
                Messages.show(error: error)
            }
        }
        return []
    }

    var body: some View {
        VStack {
            Text("Nearby Stations")
                .font(.subheadline)
                .bold()
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, -1)

            if !observations.isEmpty {
                List(observations, id: \.0, selection: $navigation.selectedObservation) { (obs, distance) in

                    self.item(obs: obs, distance: distance)
                }
                .scrollContentBackground(.hidden)
            } else {
                Text("No location found")
            }
        }
        .onAppear {
            observations = fetchObservations()
        }
        .onReceive(navigation.refreshed) {
            observations = fetchObservations()
        }
    }

    @ViewBuilder
    func item(obs: Observation, distance: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top) {
                Text(obs.station?.name ?? "-")
                    .bold()

                Spacer(minLength: 0)

                ConditionView(obs.conditionEnum)
            }

            if let module = navigation.selectedModule {
                let presentation = ObservationPresentation(module: module)
                AttributedTextView(obs: obs, presentation: presentation)
            }

            HStack(alignment: .top) {
                let age = obs.datetime.minutesSinceNow
                Text(Date.since(minutes: age))
                    .foregroundColor(ColorRamp.color(forMinutes: age))

                Spacer(minLength: 0)

                Text("\(Int(distance/1000)) km")
            }

        }
    }
}

struct NearbyObservationsView_Previews: PreviewProvider {

    static func metar(_ raw: String) -> Metar {
        let metar = Metar().parse(raw: raw)
        metar.station = Station()
        metar.station?.name = "Helsinki-Vantaan lentoasema EFHF airport"
        return metar
    }

    static var previews: some View {
            NearbyObservationsView(observations: [
                (metar("EFHK 091950Z 05006KT 9500 -RADZ BR FEW053 BKN045 05/04 Q1009 NOSIG="), 100)
            ])
            .environmentObject(NavigationManager())
        }
    }
