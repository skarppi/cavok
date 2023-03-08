//
//  ConditionView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 7.3.2023.
//

import SwiftUI

struct ConditionView: View {
    var condition: WeatherConditions

    init(_ condition: WeatherConditions) {
        self.condition = condition
    }

    var body: some View {
        Text(condition.toString())
            .padding(.horizontal, 7.5)
            .foregroundColor(.white)
            .background(
                ColorRamp.color(for: condition, alpha: 0.8)
            )
            .cornerRadius(15)
    }
}

struct ConditionView_Previews: PreviewProvider {
    static var previews: some View {
        ConditionView(WeatherConditions.INSTRUMENT)
    }
}
