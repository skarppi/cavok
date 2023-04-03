//
//  Observation.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 05.01.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import RealmSwift

public enum WeatherConditions: Int16 {
    case NA = 0, VISUAL = 1, MARGINAL = 2, INSTRUMENT = 3

    func toString() -> String {
        switch self {
        case .VISUAL: return "V"
        case .MARGINAL: return "M"
        case .INSTRUMENT: return "I"
        default: return "-"
        }
    }
}

public struct WindData {
    public var direction: Int?
    public var speed: Int?
    public var gust: Int?
    public var variability: String?
}

struct Observations {
    let metars: [Metar]
    let tafs: [Taf]
}

open class Observation: Object, Identifiable {
    // current date, will be used to parse dates
    var now: Date = Date()

    @Persisted var type: String = ""
    @Persisted var identifier: String = ""

    // A cloud base (or the base of the cloud) is the lowest altitude of the visible portion of a cloud
    @Persisted var cloudBase: Int?

    // ceiling is a measurement of the height of the base of the lowest clouds
    // that cover more than half of the sky (more than 4 oktas) relative to the ground
    @Persisted var cloudCeiling: Int?
    @Persisted var condition: Int16 = 0
    @Persisted var datetime: Date = Date()
    @Persisted(primaryKey: true) var raw: String = ""
    @Persisted var clouds: String?
    @Persisted var supplements: String?
    @Persisted var visibilityGroup: String?
    @Persisted var visibility: Int?
    @Persisted var weather: String?
    @Persisted var windGroup: String?
    @Persisted var windDirection: Int?
    @Persisted var windGust: Int?
    @Persisted var windSpeed: Int?
    @Persisted var windVariability: String?

    @Persisted var station: Station?

    // distance of the station
    public var distance: Double?

    public var conditionEnum: WeatherConditions {
        get { return WeatherConditions(rawValue: self.condition) ?? .NA }
        set { self.condition = newValue.rawValue }
    }

    public var id: String {
        return raw
    }

    public var wind: WindData {
        get { return WindData(
            direction: windDirection,
            speed: windSpeed,
            gust: windGust,
            variability: windVariability)
        }
        set {
            self.windDirection = newValue.direction
            self.windSpeed = newValue.speed
            self.windGust = newValue.gust
            self.windVariability = newValue.variability
        }
    }

    open func parse(raw: String) -> Self {
        self.raw = raw
        return self
    }

    // MARK: - Date format

    // calendar without any daylight savings issues
    func zuluCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.init(secondsFromGMT: 0)!
        return cal
    }

    // 041600Z indicates the day of the month (the 4th) followed by the time of day (1600 Zulu time).
    func parseDate(value: String?, dayOffset: Int = 0) -> Date? {
        if let value = value,
           let day = Int(value.subString(0, length: 2)),
           let hour = Int(value.subString(2, length: 2)),
           let minute = Int(value.subString(4, length: 2)) {

            let cal = zuluCalendar()

            // date components
            var components = cal.dateComponents([.day, .month, .year], from: now)

            if components.day! < day {
                // date is in the future, so must be from previous month
                components.month = components.month! - 1
            }

            components.day = day + dayOffset
            components.hour = hour
            components.minute = minute

            return cal.date(from: components)
        }
        return nil
    }

    // MARK: - Wind parsers

    // 12012G30KT indicates the wind direction is from 120° at a speed of 23 knots gusting 30 knots
    func parseWind(value: String?) -> WindData? {
        if let value = value, let match = value.getMatches("(\\d{3}|VRB|///)(\\d{2}|//)(G(\\d{2}))*KT").first {
            var windData = WindData()
            windData.direction = Int(value[match.range(at: 1)])
            windData.speed = Int(value[match.range(at: 2)])
            if match.range(at: 4).length > 0 {
                windData.gust = Int(value[match.range(at: 4)])
            }
            return windData
        }
        return nil
    }

    // 090V150 indicates the wind direction is varying from 90° to 150°
    func parseWindVariability(value: String?) -> Bool {
        return value?.isMatch("([0-9]{3})V([0-9]{3})") ?? false
    }

    // MARK: - Visibility Parsers

    func isVisibility(field: String) -> Bool {
        // 10SM
        if field.contains("SM") {
            return true
        }

        // When the horizontal visibility is not the same in all directions,
        // the minimum visibility is given for VVVV followed, without a space,
        // by Dv, the direction of the visibility observed given by a one or two
        // letter indicator of the eight points of the compass (N, NE, etc.).

        // 1400 indicates the prevailing visibility is 1,400m
        // 9999NVD = No Directional Variation (available)
        if field.isMatch("([0-9]{4})(N|NE|E|SE|S|SW|W|NW|NVD){0,1}") {
            return true
        }

        // In case of poor visibility, the direction can also be displayed per runway.
        // This is also called the RVR (Runway Visual Range).
        // An RVR is usually not reported until visibility is less than 2000 meters.
        // Examples of an RVR:
        // R23/0500 visibility for runway 23 is 500 meters
        // R23/P0500 visibility for runway 23 is more (P) than 500 meters
        // R23/M0500 visibility for runway 23 is less (M) than 500 meters
        // R23/0500V1500 visibility for runway 23 varies between 500 and 1500 meters
        // R23/0500U visibility for runway 23 is 500 meters but increases (U)
        // R23/0500D visibility for runway 23 is 500 meters but decreases (D)
        return field.isMatch("R[0-9]{2}/")
    }

    // the lowest horizontal visibility if multiple directions
    func horizontalVisibility() -> Int? {
        return visibilityGroup?.components(separatedBy: " ").compactMap({ value -> Int? in
            if let mileSeparator = value.range(of: "SM") {
                return Int(value[..<mileSeparator.lowerBound]).map { $0*1609 }
            } else if value.isMatch("R[0-9LCR]{2,3}/") {
                // RVR, take the first 4 digits from any runway
                let vis = value.dropFirst(3).filter(\.isWholeNumber)
                let number = Int(vis.subString(0, length: min(vis.length, 4)))

                // FT indicates the units for RVR are feet
                if value.contains("FT") {
                    return number.map { Int(Double($0) / 3.281) }
                }

                return number
            } else if value.length >= 4 {
                return Int(value[..<value.index(value.startIndex, offsetBy: 4)])
            } else {
                print("Unknown visibility \(value)")
                return nil
            }
        }).min()
    }

    // Clouds cannot be seen because of fog or heavy precipitation, so vertical visibility is given instead.
    func verticalVisibility() -> Int? {
        if let clouds = self.clouds {
            return clouds.getMatches("VV(///|[0-9]{3})").compactMap { match -> Int? in
                let value = clouds[match.range(at: 1)]
                if value == "///" {
                    return 100
                } else {
                    return Int(value).map { $0 * 100 }
                }
            }.min()
        }
        return nil
    }

    // MARK: - Cloud coverage

    let oktas = ["FEW", "SCT", "OVC", "BKN"]

    let cavokSynonyms = [
        "CAVOK",
        // "No cloud/Sky clear" used worldwide but in North America is used to indicate a human generated report
        "SKC",

        // "Nil Cloud detected" automated METAR station has not detected any cloud, either due to a lack of it, or due to an error in the sensors
        "NCD",

        // "No (nil) significant cloud", i.e., none below 5,000 ft (1,500 m) and no TCU or CB. Not used in North America.
        "NSC",

        // "No clouds below 12,000 ft (3,700 m) (U.S.) or 25,000 ft (7,600 m) (Canada)",
        // used mainly within North America and indicates a station that is at least partly automated
        "CLR"
    ]

    func isCavok() -> Bool {
        return self.clouds?.contains(cavokSynonyms) ?? false
    }

    private func cavokLevel() -> Int? {
        if isCavok() {
            return 5000
        }
        return nil
    }

    private func cloudLevel(layers: [String]) -> Int? {
        if let clouds = self.clouds {
            let regex = "(" + layers.joined(separator: "|") + ")([0-9]{3})"
            return clouds.getMatches(regex).compactMap { match -> Int? in
                let level = clouds[match.range(at: 2)]
                return Int(level).map { $0 * 100 }
            }.min()
        }
        return nil
    }

    // the height above the ground or water of the base of the lowest layer of
    // cloud below 6000 meters (20,000 feet) covering more than half the sky.
    func getCeiling() -> Int? {
        return cloudLevel(layers: ["OVC", "BKN"])
    }

    // the lowest altitude of the visible portion of the cloud.
    private func getCloudBase() -> Int? {
        return cloudLevel(layers: oktas)
    }

    func isSkyCondition(field: String?) -> Bool {
        let all = cavokSynonyms + oktas + ["VV", // "Vertical Visibility" = Clouds cannot be seen because of fog or heavy precipitation, so vertical visibility is given instead
                                           "TCU", // Towering cumulus cloud
                                           "CB", // Cumulonimbus cloud
                                           "NIL", // no data
                                           "/"]

        if let field = field {
            return all.contains { item in
                return field.hasPrefix(item)
            }
        }
        return false
    }

    private func weatherLevel() -> Int? {
        if let weather = self.weather {
            if weather.contains(["FG", "BR"]) {
                return 100
            } else if weather.contains(["DU", "FU", "HZ"]) {
                return 750
            }
        }
        return nil
    }

    func getCombinedCloudBase() -> Int? {
        return [
            self.cavokLevel(),
            self.getCloudBase(),
            self.verticalVisibility(),
            self.weatherLevel()
        ].compactMap { $0 }.min()
    }

    // MARK: - General conditions

    func parseCondition() -> WeatherConditions {
        let ceiling: Int = [
            self.getCeiling(),
            self.verticalVisibility()
        ].compactMap { $0 }.min() ?? 5000

        let vis = self.visibility ?? -1
        if (0 <= ceiling && ceiling < 1500) || (0 <= vis && vis < 5000) {
            return WeatherConditions.INSTRUMENT
        } else if (1500 <= ceiling && ceiling < 3000) || (5000 <= vis && vis < 8000) {
            return WeatherConditions.MARGINAL
        } else if 3000 <= ceiling && 8000 <= vis {
            return WeatherConditions.VISUAL
        } else {
            return WeatherConditions.NA
        }
    }
}
