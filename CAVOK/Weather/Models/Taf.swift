//
//  Taf.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 05.07.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

public class Taf: Observation {

    @objc public dynamic var from = Date()
    @objc public dynamic var to = Date()

    // swiftlint:disable:next function_body_length
    override public func parse(raw: String) -> Self {
        _ = super.parse(raw: raw)

        let parser = Tokenizer(raw: self.raw)

        if parser.peek() == "TAF" {
            parser.next()
        }

        if let type = parser.peek() {
            if type.contains(["COR", "AMD"]) {
                self.type = type
                parser.next()
            }
        }

        // identifier
        self.identifier = parser.pop()!

        let time = parseDate(value: parser.peek())
        if let time = time {
            self.datetime = time
            parser.next()
        }

        // validity start and end
        if let (from, to) = parse(validity: parser.pop()) {
            if time == nil {
                self.datetime = from
            }
            self.from = from
            self.to = to
        } else {
            print("No TAF validity for \(raw)")
            self.from = self.datetime
            self.to = zuluCalendar().date(byAdding: .hour, value: 24, to: self.datetime)!
        }

        if let wind = parseWind(value: parser.peek()) {
            self.wind = wind
            self.windGroup = parser.pop()
        } else {
            self.wind = WindData()
            self.windGroup = nil
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

        self.supplements = parser.all().joined(separator: " ")

        // post-process

        if self.visibility == nil && isCavok() {
            self.visibility = 10000
        }

        self.condition = self.parseCondition().rawValue

        return self
    }

    private func parse(validity: String?) -> (Date, Date)? {
        if let validity = validity, validity != "NIL", !validity.hasSuffix("Z") {
            let components = validity.components(separatedBy: "/").map { component -> Date in
                if component.hasSuffix("24") {
                    let day = component.subString(0, length: 2)
                    return self.parseDate(value: "\(day)0000Z", dayOffset: 1)!
                }
                return self.parseDate(value: "\(component)00Z")!
            }
            return (components[0], components[1])
        }
        return nil

    }

}

#if DEBUG
extension Taf {
    static func taf(_ raw: String) -> Taf {
        let taf = Taf().parse(raw: raw)
        taf.station = Station()
        taf.station?.name = "Helsinki-Vantaan lentoasema"
        return taf
    }
}
#endif
