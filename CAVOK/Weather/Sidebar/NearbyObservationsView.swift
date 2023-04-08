//
//  NearbyObservationsView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 5.3.2023.
//

import SwiftUI

struct NearbyObservationsView: View {
    @EnvironmentObject var navigation: NavigationManager

    @State var observations: [Metar] = []

    let now: Date

    @Environment(\.isPreview) var isPreview

    func fetchObservations() -> [Metar] {
        guard !isPreview else {
            return Observations.testData.metars
        }

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
                ForEach(observations) { obs in
                    StationListItemView(obs: obs, now: now)
                }
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

    static var previews: some View {
            NearbyObservationsView(observations: [Metar.metar1], now: Date())
            .environmentObject(NavigationManager())
        }
    }
