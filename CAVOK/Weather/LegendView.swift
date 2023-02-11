//
//  LegendView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 27.6.2021.
//

import SwiftUI

public struct Legend {
    var unit: String
    var gradient: [UIColor]
    var titles: [String]
}

struct LegendView: View {
    var module: Module

    var ramp: ColorRamp

    let width: CGFloat = 20
    let height: CGFloat = 150

    // how much overlap in gradient to each direction
    let overlap: CGFloat = 0.05

    @Environment(\.colorScheme) var colorScheme

    init(module: Module) {
        self.module = module
        ramp = ColorRamp(module: module)
    }

    func generateGradient() -> Gradient {

        let colors = ramp.steps.map { step in ramp.color(for: step.lower)}

        let steps = module.legend.count

        let stops: [[Gradient.Stop]] = Array(1..<steps).map { step in

            let top = steps - step
            let bottom = steps - step - 1

            let location = CGFloat(step) / CGFloat(steps)

            return [
                Gradient.Stop.init(
                    color: colors[top],
                    location: location - overlap),
                Gradient.Stop.init(
                    color: colors[bottom],
                    location: location + overlap)]
        }

        return Gradient(stops: stops.flatMap { $0 })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(module.unit)
                .offset(x: 22)

            HStack(spacing: 2) {
                LinearGradient(
                    gradient: generateGradient(),
                    startPoint: .top,
                    endPoint: .bottom)
                    .frame(width: width)

                VStack(spacing: 0) {
                    ForEach(ramp.titles.reversed(), id: \.self) { title in
                        Text(title)
                            .frame(maxHeight: .infinity)
                    }
                }.frame(height: height)
            }
            .frame(height: height)
        }
        .foregroundColor(Color.primary)
        .padding(10)
        .background(Color.white.opacity(0.25))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue, lineWidth: 1)
        )
    }
}

struct LegendView_Previews: PreviewProvider {
    static var previews: some View {
        LegendView(
            module: Module(
                key: ModuleKey.ceiling,
                title: "Test",
                unit: "FL",
                legend: ["01": "000", "02": "005", "03": "010", "04": "015", "05": "020"]
            )
        )

        LegendView(
            module: Modules.available[0]
        ).preferredColorScheme(.dark)

    }
}
