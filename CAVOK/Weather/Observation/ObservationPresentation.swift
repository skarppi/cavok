//
//  ObservationPresentation.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 9.2.2023.
//

import Foundation
import SwiftUI

struct ObservationPresentation {
    var module: Module
    var ramp: ColorRamp

    init(module: Module) {
        self.module = module
        self.ramp = ColorRamp(module: module)
    }

    func mapper(_ observation: Observation) -> (value: Int?, source: String?) {
        switch module.key {
        case .ceiling:
            return (observation.cloudHeight, observation.clouds)
        case .visibility:
            return (observation.visibility, observation.visibilityGroup)
        case .temp:
            let metar = observation as? Metar
            return (metar?.spreadCeiling(), metar?.temperatureGroup)
        default:
            return (nil, nil)
        }
    }

    func split(observation: Observation) -> ObservationPresentationData {
        let str = observation.raw
        let mapped = self.mapper(observation)

        if let value = mapped.value, let source = mapped.source {
            if let range = str.range(of: source) {
                let color = self.ramp.color(for: Int32(value))
                return ObservationPresentationData(
                    start: String(str[..<range.lowerBound]),
                    highlighted: String(str[range]),
                    end: String(str[range.upperBound...]),
                    color: color
                )
            }
        }
        return ObservationPresentationData(start: str)
    }
}

struct ObservationPresentationData {
    var start: String
    var highlighted: String = ""
    var end: String = ""
    var color: Color = Color.black
}
