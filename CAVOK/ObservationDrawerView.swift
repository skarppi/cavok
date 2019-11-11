//
//  ObservationDrawerView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 9.11.2019.
//  Copyright © 2019 Juho Kolehmainen. All rights reserved.
//

import SwiftUI
import UIKit

struct ObservationDrawerView: View {
    var presentation: ObservationPresentation
    var obs: Observation
    var observations: Observations
    var closedAction: (() -> Void)
        
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(obs.station?.name ?? "-")
                    .font(Font.system(size: 22))
                Spacer()
                Button(action: closedAction) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding()
                }
            }.padding(.leading)
            
            AttributedText(data: self.presentation.split(observation: obs))
                .padding()
            
            ObservationList(
                title: "Metar history",
                observations: observations.metars,
                presentation: presentation)
            
            ObservationList(
                title: "Taf",
                observations: observations.tafs,
                presentation: presentation)
        }
    }
}

struct ObservationList: View {
    var title: String
    var observations: [Observation]
    var presentation: ObservationPresentation
    
    var body: some View {
        Group {
            if !observations.isEmpty {
                Text(title)
                    .font(Font.system(.headline))
                    .padding(.leading)
                List(observations.reversed()) { metar in
                    AttributedText(data: self.presentation.split(observation: metar))
                }
            }
        }
    }
}

struct AttributedText: View {
    var data: ObservationPresentationData
    
    var body: some View {
        Group {
            Text(data.start)
                .font(.system(.callout))
            + Text(data.highlighted)
                .font(.system(.callout))
                .foregroundColor(Color(data.color))
            + Text(data.end)
                .font(.system(.callout))
        }
    }
}

struct ObservationDrawerView_Previews: PreviewProvider {
    static let presentation = ObservationPresentation(
        mapper: { ($0.cloudHeight.value, $0.clouds) },
        ramp: ColorRamp(moduleType: Ceiling.self)
    )
    static let observations = Observations(
        metars: [
            metar("METAR EFHK 091950Z 05006KT 3500 -RADZ BR FEW003 BKN005 05/04 Q1009 NOSIG="),
            metar("METAR EFHK 091920Z 04006KT 4000 -DZ BR BKN004 05/05 Q1009="),
            metar("METAR EFHK 091850Z 07004KT 040V130 4000 BR BKN005 05/05 Q1009="),
            metar("METAR EFHK 091820Z 07003KT 4000 BR BKN005 05/05 Q1009="),
            metar("EFHK 091750Z 06004KT CAVOK 05/05 Q1009="),
            metar("METAR EFHK 091720Z 06004KT 6000 BKN006 05/05 Q1009="),
            metar("METAR EFHK 091650Z 08004KT 7000 SCT004 BKN006 05/05 RMK AO2 SLP135 T01170028 10144 20111 Q1009=")
        ],
        tafs: [
            taf("TAF EFHK 121430Z 1215/1315 24008KT CAVOK TEMPO 1305/1313 SHRA BKN012 BKN020CB PROB30 TEMPO 1305/1312 6000 TSRA")
        ])
    
    static var previews: some View {
        ObservationDrawerView(presentation: presentation,
                              obs: observations.metars[0],
                              observations: observations,
                              closedAction: { () in print("Closed")})
            .frame(height: 200)
    }
    
    static func metar(_ raw: String) -> Metar {
        let metar = Metar()
        metar.parse(raw: raw)
        metar.station = Station()
        metar.station?.name = "Helsinki-Vantaan lentoasema EFHF airport"
        return metar
    }
    
    static func taf(_ raw: String) -> Taf {
        let taf = Taf()
        taf.parse(raw: raw)
        taf.station = Station()
        taf.station?.name = "Helsinki-Vantaan lentoasema EFHF airport"
        return taf
    }
}
