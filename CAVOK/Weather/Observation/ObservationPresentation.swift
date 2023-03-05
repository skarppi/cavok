//
//  ObservationPresentation.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 9.2.2023.
//

import Foundation
import SwiftUI

typealias ObservationGroup = (value: Int?, source: String?)

struct ObservationPresentation {
    var modules: [Module]
    var ramps: [ColorRamp]

    init(modules: [Module]) {
        self.modules = modules
        self.ramps = modules.map { module in ColorRamp(module: module) }
    }
    init(module: Module) {
        self.init(modules: [module])
    }

    func mapper(_ observation: Observation, module: Module? = nil) -> ObservationGroup {
        switch (module ?? modules.first)?.key {
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

    func split(observation: Observation) -> [ObservationPresentationData] {
        let str = observation.raw

        // all groups to be highlighted
        let groups: [ObservationGroup] = modules.map { module in
            self.mapper(observation, module: module)
        }.filter { group in
            // remove no-matches
            group.value != nil && group.source != nil
        }.reduce(into: []) { result, group in
            // remove duplicate groups, e.g. CAVOK can be colored only once
            if !result.contains(where: { $0.source == group.source }) {
                result.append(group)
            }
        }

        let rangesAndColors = groups.enumerated().compactMap { (index, group) in
            let range = str.range(of: group.source!)
            let color = self.ramps[index].color(for: Int32(group.value!))
            return (range: range, color: color)
        }.filter { rangeAndColor in
            rangeAndColor.range != nil
        }.sorted { range1, range2 in
            // groups have to be sorted in ascending order
            range1.range!.lowerBound < range2.range!.lowerBound
        }

        guard !rangesAndColors.isEmpty else {
            // no highlighting, just the string
            return [ObservationPresentationData(start: str)]
        }

        return rangesAndColors.enumerated().map { (index, rangeAndColor) in
            let (range, color) = (rangeAndColor.range!, rangeAndColor.color)

            // current group starts after the previous entry, or from the beginning
            let start = index > 0 ? range.lowerBound : str.startIndex

            // groups ends before the next entry, or end of the string
            let end = index < (rangesAndColors.count - 1) ? rangesAndColors[index + 1].range!.lowerBound : str.endIndex

            return ObservationPresentationData(
                start: String(str[start..<range.lowerBound]),
                highlighted: String(str[range]),
                end: String(str[range.upperBound..<end]),
                color: color
            )
        }
    }
}

struct ObservationPresentationData {
    var start: String
    var highlighted: String = ""
    var end: String = ""
    var color: Color = Color.black
}
