//
//  AttributedTextView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 6.2.2023.
//

import SwiftUI

struct AttributedTextView: View {
    var obs: Observation
    var presentation: ObservationPresentation

    var data: ObservationPresentationData {
        presentation.split(observation: obs)
    }

    var body: some View {
        Text(data.start) +
        Text(data.highlighted).foregroundColor(data.color) +
        Text(data.end)
    }
}

struct AttributedTextView_Previews: PreviewProvider {
    static let presentation = ObservationPresentation(
        module: Module(key: ModuleKey.ceiling,
                       title: "ceil",
                       unit: "FL",
                       legend: ["0000": "000", "0500": "005", "1000": "010", "1500": "015", "2000": "020", "5000": "050"]
                      )
    )

    static let metar = {
        let metar = Metar()
        metar.parse(raw: "METAR EFHK 091920Z 04006KT 4000 -DZ BR BKN004 05/05 Q1009=")
        metar.station = Station()
        metar.station?.name = "Helsinki-Vantaan lentoasema EFHF airport"
        return metar
    }()

    static var previews: some View {
        AttributedTextView(obs: metar, presentation: presentation )
    }
}
