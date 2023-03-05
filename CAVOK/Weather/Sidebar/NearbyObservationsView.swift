//
//  NearbyObservationsView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 5.3.2023.
//

import SwiftUI

struct NearbyObservationsView: View {
    @EnvironmentObject var navigation: NavigationManager

    let weatherService = WeatherServer()
    let presentation = ObservationPresentation(modules: Modules.available)

    @State var observation: Observation?

    @State var observations: [WithDistance<Observation>] = []

    func fetchObservations() -> [WithDistance<Observation>] {
        if let location = LastLocation.load() {
            do {
                return try weatherService.query.nearby(location: location)
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
                    VStack(alignment: .leading) {
                        Text("\(Int(distance/1000)) km \(obs.station!.name)")
                        AttributedTextView(obs: obs, presentation: presentation)
                    }

                }
            } else {
                Text("No location found")
            }
        }
        .navigationTitle(observation?.identifier ?? "Nearby Stations")
        .onAppear {
            observations = fetchObservations()
        }
        .onReceive(navigation.refreshed) {
            observations = fetchObservations()
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
