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

    var highlights: [ObservationPresentationData] {
        presentation.split(observation: obs)
    }

    var body: some View {
        highlights.reduce(Text("")) { acc, group in
            acc +
            Text(group.start) +
            Text(group.highlighted).foregroundColor(group.color) +
            Text(group.end)
        }
    }
}

struct AttributedTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AttributedTextView(obs: Metar().parse(raw: "EFHK 091920Z 04006KT 4000 -DZ BR BKN004 05/05 Q1009="),
                               presentation: ObservationPresentation(modules: Modules.available)
            )
        }
    }
}
