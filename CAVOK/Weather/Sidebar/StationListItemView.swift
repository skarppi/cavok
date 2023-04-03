//
//  StationListItemView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 26.3.2023.
//

import SwiftUI

struct StationListItemView: View {
    @EnvironmentObject var navigation: NavigationManager

    let obs: Observation

    var body: some View {
        if obs.isInvalidated {
            Group {}
        } else {
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

                    if let distance = obs.distance {
                        Text("\(Int(round(distance/1000))) km")
                    }
                }

            }.onTapGesture {
                navigation.selectedObservation = obs
            }
        }
    }
}

struct StationListItemView_Previews: PreviewProvider {
    static var previews: some View {
        StationListItemView(obs: Metar.metar1)
            .environmentObject(NavigationManager())
    }
}
