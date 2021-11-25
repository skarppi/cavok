//
//  ConfigDrawerView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 31.3.2021.
//

import SwiftUI

struct ConfigDrawerView: View {

    var closedAction: ((WeatherRegion) -> Void)

    @EnvironmentObject var region: WeatherRegion

    @State var errorMsg: String?

    func updatePosition() {
        if let location = LastLocation.load() {
            region.center = location
        } else {
            errorMsg = "Unknown location"
            Timer.scheduledTimer(withTimeInterval: 10, repeats: false) {_ in
                errorMsg = nil
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            DrawerTitleView(title: "Weather region", action: {
                closedAction(region)
            })
            HStack {
                Stepper("Radius \(region.radius) km",
                        value: $region.radius,
                        in: 100...3000,
                        step: region.radius >= 1000 ? 200 : 100
                )
            }

            if let error = errorMsg {
                Text(error)
                    .foregroundColor(Color(ColorRamp.color(for: .IFR, alpha: 1)))
            } else {
                Text("Found \(region.matches) stations")
                    .foregroundColor(.blue)
            }

            Button(action: updatePosition) {
                HStack(spacing: 10) {
                    Text("Center Aroud My Location")
                    Image(systemName: "location")
                }.padding()
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.accentColor, lineWidth: 1)
            )
        }
        .phoneOnlyStackNavigationView()
        .padding(.horizontal)
        .edgesIgnoringSafeArea(.all)
    }
}

struct ConfigDrawerView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigDrawerView(
            closedAction: { _ in print("Closed") }
        ).environmentObject(WeatherRegion(center: MaplyCoordinate(), radius: 500))
    }
}
