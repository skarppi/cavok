//
//  NearbyObservationsView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 5.3.2023.
//

import SwiftUI

struct NearbyObservationsView: View {
    @EnvironmentObject var navigation: NavigationManager

    @State var observations: [WithDistance<Metar>] = []

    func fetchObservations() -> [WithDistance<Metar>] {
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
        Section(header: Text("Nearby Stations")) {
            if !observations.isEmpty {
                ForEach(observations, id: \.element) { obs in
                    StationListItemView(obs: obs.element, distance: obs.distanceMeters)
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
                WithDistance(element: metar("EFHK 091950Z 05006KT 9500 -RADZ BR FEW053 BKN045 05/04 Q1009 NOSIG="), distanceMeters: 100.0)
            ])
            .environmentObject(NavigationManager())
        }
    }
