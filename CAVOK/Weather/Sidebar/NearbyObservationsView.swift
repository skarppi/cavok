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
        Group {
            if !observations.isEmpty {
                List(observations, id: \.0, selection: $navigation.selectedObservation) { (obs, distance) in

                    self.item(obs: obs, distance: distance)
                }
            } else {
                Text("No location found")
            }
        }
        .navigationTitle("Nearby Stations")
        .onAppear {
            observations = fetchObservations()
        }
        .onReceive(navigation.refreshed) {
            observations = fetchObservations()
        }
    }

    @ViewBuilder
    func item(obs: Observation, distance: Int) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(obs.station?.name ?? "-")
                    .bold()

                if let module = navigation.selectedModule {
                    let presentation = ObservationPresentation(module: module)
                    AttributedTextView(obs: obs, presentation: presentation)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {

                let condition = obs.conditionEnum.toString()
                Text(condition)
                    .padding(.horizontal)
                    .foregroundColor(.white)
                    .background(
                        ColorRamp.color(for: obs.conditionEnum, alpha: 0.8)
                    )
                    .cornerRadius(15)

                Text("\(Int(distance/1000)) km")

                let age = obs.datetime.minutesSinceNow
                Text(Date.since(minutes: age))
                    .foregroundColor(ColorRamp.color(forMinutes: age))
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
            (metar("EFHK 091950Z 05006KT 3500 -RADZ BR FEW003 BKN005 05/04 Q1009 NOSIG="), 100)
        ])
        .environmentObject(NavigationManager())
    }
}
