//
//  Adds.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 24.01.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import SwiftyJSON

enum AddsSource: String {
    case STATION = "stationinfo", METAR = "metar", TAF = "tafs"
}

public class AddsService {

    class func fetchStations(at region: WeatherRegion) async throws -> [Station] {
        let data = try await fetch(dataSource: AddsSource.STATION, with: ["format": "json"], at: region)

        let stations = try JSON(data: data).arrayValue.map { station -> Station in
            let name = station["site"].stringValue.split(separator: "Arpt").first
            return Station(
                identifier: station["icaoId"].stringValue,
                name: String(name ?? "-"),
                latitude: station["lat"].floatValue,
                longitude: station["lon"].floatValue,
                elevation: station["elev"].floatValue,
                source: .adds,
                hasMetar: true,
                hasTaf: station["priority"].intValue <= 5
            )
        }
        
        print("Found \(stations.count) ADDS stations")
        return stations
    }

    class func fetchObservations(_ source: AddsSource,
                                 at region: WeatherRegion,
                                 station: String? = nil,
                                 history: Bool = true) async throws -> [Observation] {
        guard let query = [
            "hours": history ? "3" : nil,
            "ids": station,
            "format": "raw",
            "taf": "true"
        ].filter({ $0.value != nil }) as? [String: String] else { return [] }
        
        let data = try await fetch(dataSource: source, with: query, at: region)
        
        let result = String(data: data, encoding: String.Encoding.ascii)?.split(whereSeparator: \.isNewline)
        return result?.map { raw in
            
            if raw.starts(with: "TAF ") {
                return Taf().parse(raw: String(raw))
            } else {
                return Metar().parse(raw: String(raw))
            }
        } ?? []
    }
    
    private class func fetch(dataSource: AddsSource,
                             with: [String: String] = [:],
                             at region: WeatherRegion) async throws -> Data {
        var params = [
            "bbox": "\(region.minLat),\(region.minLon),\(region.maxLat),\(region.maxLon)",
        ]
        with.forEach { params[$0] = $1 }

        let host = UserDefaults.cavok?.string(forKey: "addsURL")
        var components = URLComponents(string: "\(host!)/\(dataSource.rawValue)")!
        components.queryItems = params.map { name, value in URLQueryItem(name: name, value: value) }
        
        print("Fetching ADDS data from \(components.url!)")

        do {
            let (data, _)  = try await URLSession.shared.data(from: components.url!)
            return data
        } catch Weather.error(let msg) {
            print(msg)
            throw Weather.error(msg: "ADDS temporarily unavailable")
        }
    }
}
