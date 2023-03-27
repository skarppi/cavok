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
    let distance: Double?

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

                    if let distance = distance {
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
    static func metar(_ raw: String) -> Metar {
        let metar = Metar().parse(raw: raw)
        metar.station = Station()
        metar.station?.name = "Helsinki-Vantaan lentoasema EFHF airport"
        return metar
    }

    static var previews: some View {
        StationListItemView(obs: metar("EFHK 091950Z 05006KT 9500 -RADZ BR FEW053 BKN045 05/04 Q1009 NOSIG="), distance: 1501)
            .environmentObject(NavigationManager())
    }
}
