//
//  Metar.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 21.10.12.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import RealmSwift

public class Metar: Observation {

    @Persisted var altimeter: Int?
    @Persisted var runwayVisualRange: String?

    @Persisted var dewPoint: Int?
    @Persisted var temperature: Int?
    @Persisted var temperatureGroup: String?

    // The cloud base can be estimated from surface measurements of air temperature and
    // humidity by calculating the lifted condensation level.
    // - Find the difference between the surface temperature and the dew point.
    //   This value is known as the "spread".
    // - Divide the spread °C by 2.5 then multiply by 1000.
    //   This will give you cloud base in feet AGL (Above Ground Level)
    // https://en.wikipedia.org/wiki/Cloud_base
    func spreadCeiling() -> Int? {
        if let temp = temperature, let dewPoint = dewPoint {
            return (temp - dewPoint) * 400
        } else {
            return nil
        }
    }

    // MARK: - Parsers

    override public func parse(raw: String) -> Self {
        _ = super.parse(raw: raw)

        let parser = Tokenizer(raw: self.raw)

        // identifier
        self.identifier = parser.pop()!

        if let time = parseDate(value: parser.pop()) {
            self.datetime = time
        }

        if let type = parser.peek() {
            if type.contains(["METAR", "SPECI", "AUTO"]) {
                self.type = type
                parser.next()
            }
        }

        if let wind = parseWind(value: parser.pop()) {
            self.wind = wind
        } else {
            self.wind = WindData()
        }

        if parseWindVariability(value: parser.peek()) {
            self.windVariability = parser.pop()
        }

        if let vis = parseVisibility(value: parser.peek()) {
            self.visibility = vis

            self.visibilityGroup = parser.pop()
        } else {
            self.visibility = nil
            self.visibilityGroup = nil
        }

        self.weather = parser.loop { current in
            return isSkyCondition(field: current)
        }.joined(separator: " ")

        self.clouds = parser.loop { current in
            return !isSkyCondition(field: current)
        }.joined(separator: " ")

        self.cloudHeight = getCombinedCloudHeight()

        if let (temp, dewPoint) = parseTemperatures(parser.peek()) {
            self.temperature = temp
            self.dewPoint = dewPoint

            self.temperatureGroup = parser.pop()
        }

        if let alt = parseAltimeter(parser.peek()) {
            self.altimeter = alt

            parser.next()
        }

        self.supplements = parser.all().joined(separator: " ")

        // post-process

        if self.visibility == nil && isCavok() {
            self.visibility = 10000
            self.visibilityGroup = "CAVOK"
        }

        self.condition = self.parseCondition().rawValue

        return self
    }

    func parseTemperatures(_ value: String?) -> (Int?, Int?)? {
        if let value = value {
            let negatives = value.replace("M", with: "-")

            let components = negatives.components(separatedBy: "/")
            if components.count == 2 {
                return (Int(components[0]), Int(components[1]))
            }
        }
        return nil

    }

    // Q1020
    func parseAltimeter(_ value: String?) -> Int? {
        if let value = value {
            if value.length < 4 {
                return nil
            }
            switch (value[0], value[value.index(after: value.startIndex)...]) {
            case ("Q", let qnh): return Int(qnh)
            case ("A", let qnh): return Int(qnh).map { Int(Double($0) * 0.3386) }
            default: return nil
            }
        }
        return nil
    }
}
