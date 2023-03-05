//
//  SidebarView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 5.3.2023.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var navigation: NavigationManager

    let weatherService = WeatherServer()

    func observations() -> Observations? {
        if let observation = navigation.selectedObservation {
            do {
                return try weatherService.query.observations(for: observation.station?.identifier ?? "")
            } catch {
                Messages.show(error: error)
            }
        }
        return nil
    }

    var body: some View {
        if let observation = navigation.selectedObservation, let module = navigation.selectedModule {
            let presentation = ObservationPresentation(module: module)
            VStack {
                ObservationHeaderView(presentation: presentation,
                                      obs: observation) { () in
                    navigation.selectedObservation = nil
                }

                if let observations = observations() {
                    ObservationDetailsView(presentation: presentation,
                                           observations: observations)
                }
            }
        } else {
            NearbyObservationsView()
        }
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
            .environmentObject(NavigationManager())
    }
}
