//
//  AtisService.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 4.4.2023.
//

import Foundation

import SwiftyJSON

public class AtisService {

    static let efnu =
        Station(
            identifier: "EFNU",
            name: "Nummela",
            latitude: 60.339167,
            longitude: 24.203056,
            elevation: 0,
            source: .atis,
            hasMetar: true,
            hasTaf: false
        )

    static let atisLetters: [String?: String] = [
        "A": "ALPHA",
        "B": "BRAVO",
        "C": "CHARLIE",
        "D": "DELTA",
        "E": "ECHO",
        "F": "FOXTROT",
        "G": "GOLF",
        "H": "HOTEL",
        "I": "INDIA",
        "J": "JULIETT",
        "K": "KILO",
        "L": "LIMA",
        "M": "MIKE",
        "N": "NOVEMBER",
        "O": "OSCAR",
        "P": "PAPA",
        "Q": "QUEBEC",
        "R": "ROMEO",
        "S": "SIERRA",
        "T": "TANGO",
        "U": "UNIFORM",
        "V": "VICTOR",
        "W": "WHISKEY",
        "X": "X-RAY",
        "Y": "YANKEE",
        "Z": "ZULU"
    ]

    class func fetchStations(at region: WeatherRegion) async throws -> [Station] {
        guard region.inRange(latitude: efnu.latitude, longitude: efnu.longitude) else {
            return []
        }
        return [efnu]
    }

    class func fetchLatestObservation(at region: WeatherRegion, station: String) async throws -> String? {
        return try await fetchObservations(at: region).first?.raw
    }

    private class func toStr(_ number: Double, _ length: Int) -> String {
        toStr(Int(round(number)), length)
    }

    private class func toStr(_ number: Int, _ length: Int) -> String {
        (number < 0 ? "M" : "") + String(format: "%0\(length)d", abs(number))
    }

    class func fetchObservations(at region: WeatherRegion) async throws -> [Metar] {
//        guard region.inRange(latitude: efnu.latitude, longitude: efnu.longitude) else {
//            return []
//        }

        let url = URL(string: UserDefaults.cavok!.string(forKey: "atisURL")!)!

        print("Fetching ATIS data from \(url)")
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSON(data: data)

        guard json["result"] == "ok" else { return [] }

        let site = json["site"].stringValue.uppercased()

        return json["states"].array?.map { state in
            let report = state["report"].dictionaryValue

            let metar = Metar().parse(raw: toMetar(site: site, report: report))
            metar.atisLetter = atisLetters[report["repid"]?.string]
            metar.atisUrl = state["mp3"].string.map { "https://atis.efnu.fi/\($0)" }
            return metar
        } ?? []
    }

    private class func toMetar(site: String, report: [String: JSON]) -> String {
        let date = report["atistime"]!.stringValue

        let wind = parseWind(report: report)

        let features = report["features"]?.array?.map { $0.stringValue }

        let visibility = features?.contains("CAVOK") == false ? parseVisibility(report: report) : nil

        let clouds = parseClouds(report: report)

        let temperature: String?
        if let temp = report["temperature"]?.double, let dewpoint = report["dewpoint"]?.double {
            temperature = toStr(temp, 2) + "/" + toStr(dewpoint, 2)
        } else {
            temperature = nil
        }

        let qnh = report["qnh"]?.int.map { "Q\($0)" }

        let components: [String?] = [
            site,
            date,
            "AUTO",
            wind,
            visibility,
            features?.filter { !$0.hasPrefix("RE") }.joined(separator: " "),
            clouds,
            temperature,
            qnh,
            features?.filter { $0.hasPrefix("RE") }.joined(separator: " ")
        ]

        return components
            .filter { $0?.isEmpty == false }
            .compactMap { $0 }
            .joined(separator: " ") + "="
    }

    private class func parseVisibility(report: [String: JSON]) -> String? {
        if let vis = report["visibility"]?.int {
            return String(min(9999, vis))
        } else {
            return nil
        }
    }

    private class func parseClouds(report: [String: JSON]) -> String? {
        return report["clouds"]?.array?.map { cloud in
            let comp = cloud.arrayValue
            return [
                comp[0].stringValue,
                toStr(comp[1].intValue, 3),
                comp.dropFirst(2).map { $0.stringValue }.joined()
            ].joined()
        }.joined(separator: " ")
    }

    // ICAO Annex 3
    // § 4.1.5.2:
    private class func parseWind(report: [String: JSON]) -> String? {
        guard let windDir = report["wind_dir"]?.int.map({ toStr($0, 3) }),
              let windKt = report["wind_kt"]?.double else {
            return "/////KT"
        }

        let gust = report["wind_gust_kt"]?.double.map { gustKt in
            if (gustKt - windKt) > 10 {
                return "G\(toStr(gustKt, 2))"
            } else {
                return ""
            }
        } ?? ""

        let wind = "\(windDir)\(toStr(windKt, 2))\(gust)KT"

        if let windDirMin = report["wind_dir_min"]?.int,
            let windDirMax = report["wind_dir_max"]?.int,
            let variation = report["wind_dir_diff"]?.int {

            if variation < 60 {
                return wind
            } else if windKt < 3 {
                // when the total variation is 60° or more and less than 180° and the wind speed is less
                // than 6 km/h (3 kt), the wind direction shall be reported as variable with no mean wind direction
                return "VRB"
            } else if variation > 180 {
                // when the total variation is 180° or more, the wind direction shall be reported as variable with
                // no mean wind direction
                return "VRB\(toStr(windKt, 2))KT"
            } else {
                // when the total variation is 60° or more and less than 180° and the wind speed is 6 km/h (3 kt)
                // or more, such directional variations shall be reported as the two extreme directions between which
                // the surface wind has varied
                return "\(wind) \(toStr(windDirMin, 3))V\(toStr(windDirMax, 3))"
            }
        } else {
            return wind
        }
    }
}
