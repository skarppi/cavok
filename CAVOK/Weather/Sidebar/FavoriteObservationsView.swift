//
//  FavoriteObservationsView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 26.3.2023.
//

import SwiftUI

struct FavoriteObservationsView: View {
    @EnvironmentObject var navigation: NavigationManager

    @State var observations: [WithDistance<Metar>] = []

    func fetchObservations() -> [WithDistance<Metar>] {
        do {
            return try WeatherServer.query.favorites(location: LastLocation.load())
        } catch {
            Messages.show(error: error)
            return []
        }
    }

    var body: some View {
        Section(header: Text("Favorite Stations")) {
            if observations.isEmpty {
                Text("No favorite stations")
            } else {
                ForEach(observations, id: \.element) { obs in
                    StationListItemView(obs: obs.element, distance: obs.distanceMeters)
                }
                .scrollContentBackground(.hidden)
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

struct FavoriteObservationsView_Previews: PreviewProvider {
    static func metar(_ raw: String) -> Metar {
        let metar = Metar().parse(raw: raw)
        metar.station = Station()
        metar.station?.name = "Helsinki-Vantaan lentoasema EFHF airport"
        return metar
    }

    static var previews: some View {
        FavoriteObservationsView(observations: [
            WithDistance(element: metar("EFHK 091950Z 05006KT 9500 -RADZ BR FEW053 BKN045 05/04 Q1009 NOSIG="), distanceMeters: 100.0)
        ])
        .environmentObject(NavigationManager())
    }
}
