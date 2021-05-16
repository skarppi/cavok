//
//  ConfigDrawerView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 31.3.2021.
//

import SwiftUI

struct DynamicSizeHelper {
    static private let baseViewWidth: CGFloat = 414.0
    static private let baseViewHeight: CGFloat = 896.0

    static func getHeight(_ height: CGFloat) -> CGFloat {
        return (height / baseViewHeight) * UIScreen.main.bounds.height
    }

    static func getWidth(_ width: CGFloat) -> CGFloat {
        return (width / baseViewWidth) * UIScreen.main.bounds.width
    }

    static func getOffsetX(_ x: CGFloat) -> CGFloat {
        return (x / baseViewWidth) * UIScreen.main.bounds.width
    }

    static func getOffsetY(_ y: CGFloat) -> CGFloat {
        return (y / baseViewHeight) * UIScreen.main.bounds.height
    }
}

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

    func newLink() {
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            DrawerTitleView(title: "Weather region", action: {  closedAction(region)
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

            HStack {
                Text("Web Links").font(.system(.title))
                Spacer()
                Button(action: newLink) {
                    Image(systemName: "plus.circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding()
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .edgesIgnoringSafeArea(.all)
    }
}

struct RegionConfigView: View {
    var title: String?
    var action: (() -> Void)

    var body: some View {
        HStack {
            Text(title ?? "-").font(.system(.title))
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

struct ConfigDrawerView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigDrawerView(
            closedAction: { _ in print("Closed") }
        ).environmentObject(WeatherRegion(center: MaplyCoordinate(), radius: 500))
    }
}
