//
//  FavoriteObservationsView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 26.3.2023.
//

import SwiftUI
import RealmSwift

struct FavoriteObservationsView: View {
    @EnvironmentObject var navigation: NavigationManager

    @State var observations: [Metar] = []

    let now: Date

    @Environment(\.isPreview) var isPreview

    func fetchObservations() -> [Metar] {
        guard !isPreview else {
            return Observations.testData.metars
        }

        do {
            return try WeatherServer.query.favorites(location: LastLocation.load())
        } catch {
            Messages.show(error: error)
            return []
        }
    }

    var body: some View {
        Section(header: Text("Favorite Stations")) {
            if observations.isEmpty == true {
                Text("No favorite stations")
            } else {
                ForEach(observations) { obs in
                    StationListItemView(obs: obs, now: now)
                }
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

    static var previews: some View {
        FavoriteObservationsView(observations: [Metar.metar1], now: Date())
            .environmentObject(NavigationManager())
    }
}
