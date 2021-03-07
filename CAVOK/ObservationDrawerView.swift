//
//  ObservationDrawerView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 9.11.2019.
//  Copyright © 2019 Juho Kolehmainen. All rights reserved.
//

import SwiftUI
import UIKit
import Pulley

public class PulleySizes {
    var collapsedHeight: CGFloat = 0
    var fullHeight: CGFloat = 0
}


struct ObservationDrawerView: View {
    var presentation: ObservationPresentation
    var obs: Observation
    var observations: Observations
    
    var sizes = PulleySizes()
    
    var closedAction: (() -> Void)
        
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                TitleRow(title: self.obs.station?.name, action: closedAction)
               
                AttributedText(obs: obs, presentation: presentation)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal).padding(.top)
            }.background(GeometryReader { proxy -> Color in
                self.sizes.collapsedHeight = proxy.frame(in: .local).maxY
                return Color.clear
            })

            ScrollView {
                VStack(alignment: .leading) {
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
        .edgesIgnoringSafeArea(.all)
        .background(GeometryReader { proxy -> Color in
            self.sizes.fullHeight = proxy.frame(in: .local).maxY
            return Color.clear
        })
    }
}

struct TitleRow: View {
    var title: String?
    var action: (() -> Void)
    
    var body: some View {
        HStack {
            Text(title ?? "-")
                .fixedSize(horizontal: false, vertical: true)
                .font(Font.system(size: 22))
                .padding(.leading)
            Spacer()
            Button(action: self.action) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding()
            }
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
                    .padding(.all)

                ForEach(observations.reversed(), id: \.self) { metar in
                    
                    AttributedText(obs: metar, presentation: self.presentation)
                        .padding(.leading)
                        .padding(.bottom,5)
                }
            }
        }
    }
}

struct AttributedText: View {
    var obs: Observation
    var presentation: ObservationPresentation
    
    var data: ObservationPresentationData {
        presentation.split(observation: obs)
    }
    
    var body: some View {
        Text(data.start)
            + Text(data.highlighted).foregroundColor(Color(data.color))
            + Text(data.end)
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
                              sizes: PulleySizes(),
                              closedAction: { () in print("Closed")})
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
