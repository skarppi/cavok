//
//  NearbyObservationsView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 5.3.2023.
//

import SwiftUI

struct NearbyObservationsView: View {
    let weatherService = WeatherServer()

    func observations() -> [Metar]? {
        if let location = LastLocation.load() {
            do {
                return try weatherService.query.nearby(location: location)
            } catch {
                Messages.show(error: error)
            }
        }
        return nil
    }

    var body: some View {
        if let observations = observations() {
            List {
                ForEach(observations) { obs in
                    Text(obs.raw)
                }
            }
            .navigationTitle("Nearby Stations")
        } else {
            Text("No location found")
        }
    }
}

struct NearbyObservationsView_Previews: PreviewProvider {
    static var previews: some View {
        NearbyObservationsView()
    }
}
