//
//  Observation.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 05.01.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import RealmSwift
import CoreLocation

public enum WeatherConditions: Int16 {
    case NA = 0, VFR = 1, MVFR = 2, IFR = 3
}

public struct WindData {
    public var direction: Int? = nil
    public var speed: Int? = nil
    public var gust: Int? = nil
    public var variability: String? = nil
}

struct ObservationPresentation {
    var mapper: (Observation) -> (value: Int?, source: String?)
    var ramp: ColorRamp
    
    func highlight(observation: Observation) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: observation.raw)
        
        let mapped = self.mapper(observation)
        if let value = mapped.value, let source = mapped.source {
            let cgColor = self.ramp.color(for: Int32(value))
            attributed.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor(cgColor: cgColor), pattern: source)
        }
        return attributed
    }
}

open class Observation: Object {
    // current date, will be used to parse dates
    var now: Date = Date()

    @objc open dynamic var type: String = ""
    @objc public dynamic var identifier: String = ""
    public var cloudHeight = RealmOptional<Int>()
    @objc public dynamic var condition: Int16 = 0
    @objc public dynamic var datetime: Date = Date()
    @objc public dynamic var raw: String = ""
    @objc public dynamic var clouds: String?
    @objc public dynamic var supplements: String?
    @objc public dynamic var visibilityGroup: String?
    public let visibility = RealmOptional<Int>()
    @objc public dynamic var weather: String?
    private let windDirection = RealmOptional<Int>()
    private let windGust = RealmOptional<Int>()
    private let windSpeed = RealmOptional<Int>()
    @objc public dynamic var windVariability: String?
    
    @objc public dynamic var station: Station?
    
    public var conditionEnum: WeatherConditions {
        get { return WeatherConditions(rawValue: self.condition) ?? .NA }
        set { self.condition = newValue.rawValue }
    }
    
    override public static func primaryKey() -> String? {
        return "raw"
    }
    
    public var wind: WindData {
        get { return WindData(
            direction: windDirection.value,
            speed: windSpeed.value,
            gust: windGust.value,
            variability: windVariability)
        }
        set {
            self.windDirection.value = newValue.direction
            self.windSpeed.value = newValue.speed
            self.windGust.value = newValue.gust
            self.windVariability = newValue.variability
        }
    }
    
    open func parse(raw: String) {
        self.raw = raw
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
        if let value = value, let match = value.getMatches("(\\d{3}|VRB)(\\d{2})(G(\\d{2}))*KT").first {
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
    
    // Clouds cannot be seen because of fog or heavy precipitation, so vertical visibility is given instead.
    func verticalVisibility() -> Int? {
        if let clouds = self.clouds {
            return clouds.getMatches("VV(///|[0-9]{3})").compactMap { match -> Int? in
                let value = clouds[match.range(at: 1)]
                if value == "///" {
                    return 100;
                } else {
                    return Int(value).map{ $0 * 100 }
                }
            }.min()
        }
        return nil
    }
    
    // MARK: - Cloud coverage

    let CLOUD_COVERAGE = ["FEW","SCT","OVC","BKN"]
    
    let CAVOK_CONDITIONS = ["CAVOK", "SKC", "NCD", "NSC", "CLR"]
    
    func isCavok() -> Bool {
        return self.clouds?.contains(CAVOK_CONDITIONS) ?? false
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
    
    // the height above the ground or water of the base of the lowest layer of cloud below 6000 meters (20,000 feet) covering more than half the sky.
    private func getCeiling() -> Int? {
        return cloudLevel(layers: ["OVC","BKN"])
    }
    
    // the lowest altitude of the visible portion of the cloud.
    private func getCloudBase() -> Int? {
        return cloudLevel(layers: CLOUD_COVERAGE)
    }
    
    func isSkyCondition(field: String?) -> Bool {
        let all = CAVOK_CONDITIONS + CLOUD_COVERAGE + ["VV", "NIL", "/"]
        
        if let field = field {
            return all.contains { item in
                return field.hasPrefix(item)
            }
        }
        return false
    }
    
    // 1400 indicates the prevailing visibility is 1,400m, 9999NVD or 10SM
    func parseVisibility(value: String!) -> Int? {
        if !self.isSkyCondition(field: value) {
            if let mileSeparator = value.range(of: "SM") {
                
                return Int(value[..<mileSeparator.lowerBound]).map { $0*1609 }
            } else if value.length >= 4 {
                return Int(value[..<value.index(value.startIndex, offsetBy: 4)])
            }
        }
        return nil
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
 
    func getCombinedCloudHeight() -> Int? {
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
        
        //let ceiling = ceilingOpt ?? -1
        let vis = self.visibility.value ?? -1
        if((0 <= ceiling && ceiling < 1500) || (0 <= vis && vis < 5000)) {
            return WeatherConditions.IFR
        } else if((1500 <= ceiling && ceiling < 3000) || (5000 <= vis && vis < 8000)) {
            return WeatherConditions.MVFR
        } else if(3000 <= ceiling && 8000 <= vis) {
            return WeatherConditions.VFR
        } else {
            return WeatherConditions.NA
        }
    }
}
