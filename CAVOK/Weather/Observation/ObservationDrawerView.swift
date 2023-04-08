//
//  ObservationDrawerView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 9.11.2019.
//  Copyright © 2019 Juho Kolehmainen. All rights reserved.
//

import SwiftUI
import AVFoundation
import Combine

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

let audioPlayer = AVPlayer()
let timeControlStatus = TimeControlStatusObserver(player: audioPlayer)

struct ObservationDetailsView: View {
    @State var observations: Observations?

    @State var isFavorite: Bool = true

    @State var playerStatus = "spinner"

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

    func play() {
        if audioPlayer.timeControlStatus == .playing {
            audioPlayer.pause()
        } else if let obs = navigation.selectedObservation, let atisUrl = (obs as? Metar)?.atisUrl {
            let url = URL(string: atisUrl)!

            let playerItem = AVPlayerItem(url: url)
            audioPlayer.replaceCurrentItem(with: playerItem)
            audioPlayer.playImmediately(atRate: 1)
        }
    }

    var body: some View {

        if let presentation = navigation.presentation {

            ScrollView {
                if let obs = navigation.selectedObservation, let letter = (obs as? Metar)?.atisLetter {
                    Button(action: play) {
                        HStack(spacing: 10) {
                            Image(systemName: playerStatus)

                            Text("ATIS Information \(letter)")
                        }.padding()
                    }.buttonStyle(.bordered)
                    .tint(.accentColor)
                }

                if observations?.metars.count != 1 {
                    ObservationList(
                        title: "Metar history",
                        observations: observations?.metars ?? [],
                        presentation: presentation)
                }

                ObservationList(
                    title: "Taf",
                    observations: observations?.tafs ?? [],
                    presentation: presentation)

                AdaptiveStack(overrideOrientation: Self.isPad ? .VERTICAL : .HORIZONTAL) { _ in
                    Button(action: showMeteogram) {
                        HStack(spacing: 10) {
                            Text("Meteogram")
                            Image(systemName: "location")
                        }
                        .padding()
                        .frame(maxWidth: Self.isPad ? .infinity : nil)
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)

                    Button(action: changeFavorite) {
                        HStack(spacing: 10) {
                            Text( isFavorite ? "Unfavorite" : "Favorite")
                            Image(systemName: "heart")
                        }
                        .padding()
                        .frame(maxWidth: Self.isPad ? .infinity : nil)
                    }
                    .buttonStyle(.bordered)
                    .tint(isFavorite ? .red : .green)
                }.padding(.top)
            }
            .padding(.horizontal)
            .onAppear {
                guard !isPreview else { return }
                observations = fetchObservations()

                isFavorite = observations?.metars.first?.station?.favorite ?? false
            }
            .onDisappear {
                audioPlayer.replaceCurrentItem(with: nil)
            }.onReceive(timeControlStatus.$currentStatus) { status in
                if status == .playing {
                    playerStatus = "pause"
                } else if status == .waitingToPlayAtSpecifiedRate {
                    playerStatus = "circle.dotted"
                } else {
                    playerStatus = "play"
                }
            }
        }
    }
}

class TimeControlStatusObserver {
    @Published var currentStatus: AVPlayer.TimeControlStatus?
    private var itemObservation: AnyCancellable?

    init(player: AVPlayer?) {
        // Observe the current item changing
        itemObservation = player?.publisher(for: \.timeControlStatus).sink { newStatus in
            self.currentStatus = newStatus
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
    static let manager: NavigationManager = {

        let nav = NavigationManager()
        nav.selectedModule = Modules.visibility
        var metar = Metar.metar("EFHK 091950Z 05006KT 3500 -RADZ BR FEW003 BKN005 05/04 Q1009 NOSIG=")
        metar.atisLetter = "XRAY"
        nav.selectedObservation = metar
        return nav
    }()
    static let observations = Observations.testData

    static var previews: some View {
        VStack(alignment: .leading) {
            ObservationHeaderView()

            ObservationDetailsView(observations: observations)
        }
        .environmentObject(manager)
    }

}
