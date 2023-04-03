//
//  ObservationDrawerView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 9.11.2019.
//  Copyright © 2019 Juho Kolehmainen. All rights reserved.
//

import SwiftUI

struct ObservationHeaderView: View {
    @EnvironmentObject var navigation: NavigationManager

    var body: some View {
        if let obs = navigation.selectedObservation, let presentation = navigation.presentation {
            VStack(alignment: .leading) {
                DrawerTitleView(title: obs.station?.name, action: {
                    navigation.selectedObservation = nil
                })

                AttributedTextView(obs: obs, presentation: presentation)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top)
                    .onTapGesture {}
                    .onLongPressGesture {
                        UIPasteboard.general.string = obs.raw
                        Messages.showCopiedToClipboard()
                    }
            }.padding(.horizontal)
        }
    }
}

struct ObservationDetailsView: View {
    @State var observations: Observations?

    @State var isFavorite: Bool = true

    @EnvironmentObject var navigation: NavigationManager

    @Environment(\.isPreview) var isPreview

    func fetchObservations() -> Observations? {
        if let observation = navigation.selectedObservation {
            do {
                return try WeatherServer.query.observations(for: observation.station?.identifier ?? "")
            } catch {
                Messages.show(error: error)
            }
        }
        return nil
    }

    func showMeteogram() {
        navigation.showWebView = true
    }

    func changeFavorite() {
        if let obs = navigation.selectedObservation, let station = obs.station {

            do {
                isFavorite = try WeatherServer.query.favorite(station: station)
            } catch {
                Messages.show(error: error)
            }
        }

    }

    var body: some View {

        if let presentation = navigation.presentation {

            ScrollView {
                ObservationList(
                    title: "Metar history",
                    observations: observations?.metars ?? [],
                    presentation: presentation)

                ObservationList(
                    title: "Taf",
                    observations: observations?.tafs ?? [],
                    presentation: presentation)

                HStack {
                    Button(action: showMeteogram) {
                        HStack(spacing: 10) {
                            Text("Meteogram")
                            Image(systemName: "location")
                        }.padding()
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)

                    Button(action: changeFavorite) {
                        HStack(spacing: 10) {
                            Text( isFavorite ? "Unfavorite" : "Favorite")
                            Image(systemName: "heart")
                        }.padding()
                    }
                    .buttonStyle(.bordered)
                    .tint(isFavorite ? .red : .green)
                }
            }
            .padding(.horizontal)
            .onAppear {
                guard !isPreview else { return }
                observations = fetchObservations()

                isFavorite = observations?.metars.first?.station?.favorite ?? false
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
                    .padding(.vertical)

                ForEach(observations.reversed(), id: \.self) { metar in
                    AttributedTextView(obs: metar, presentation: self.presentation)
                        .padding(.bottom, 5)
                        .onTapGesture {}
                        .onLongPressGesture {
                            UIPasteboard.general.string = metar.raw
                            Messages.showCopiedToClipboard()
                        }
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ObservationDrawerView_Previews: PreviewProvider {
    static let manager = NavigationManager()
    static let observations = Observations(
        metars: [
            Metar.metar("EFHK 091950Z 05006KT 3500 -RADZ BR FEW003 BKN005 05/04 Q1009 NOSIG="),
            Metar.metar("EFHK 091920Z 04006KT 4000 -DZ BR BKN004 05/05 Q1009="),
            Metar.metar("EFHK 091650Z 08004KT 7000 SCT004 BKN006 "
                  + "05/05 RMK AO2 SLP135 T01170028 10144 AO2 "
                  + "SLP135 T01170028 10144 20111 Q1009=")
        ],
        tafs: [
            Taf.taf("TAF EFHK 121430Z 1215/1315 24008KT CAVOK TEMPO 1305/1313 SHRA BKN012 BKN020CB PROB30")
        ])

    init() {
        Self.manager.selectedModule = Modules.visibility
        Self.manager.selectedObservation = Self.observations.metars[0]
    }

    static var previews: some View {
        VStack {
            ObservationHeaderView()

            ObservationDetailsView(observations: observations)
        }
        .environmentObject(manager)
    }

}
