//
//  Adds.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 24.01.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import SWXMLHash
import PMKFoundation
import PromiseKit
import Gzip

enum AddsSource: String {
    case STATION = "stations", METAR = "metars", TAF = "tafs"
}

public class AddsService {
    
    class func fetchStations(at region: WeatherRegion) -> Promise<[Station]> {
        return fetch(dataSource: "stations", at: region).map { data -> [Station] in
            print("Found \(data.children.count) ADDS stations")
            
            return data.children.map { station in
                Station(
                    identifier: station["station_id"].element!.text,
                    name: station["site"].element!.text,
                    latitude: Float(station["latitude"].element!.text)!,
                    longitude: Float(station["longitude"].element!.text)!,
                    elevation: Float(station["elevation_m"].element!.text)!,
                    hasMetar: station["site_type"]["METAR"].element != nil,
                    hasTaf: station["site_type"]["TAF"].element != nil
                )
            }
        }
    }
    
    class func fetchObservations(_ source: AddsSource, history: Bool, at region: WeatherRegion) -> Promise<[String]> {
        let query = [
            "hoursBeforeNow": "3",
            "mostRecentForEachStation": String(history == false),
            "fields": "raw_text"
        ]
        return fetch(dataSource: source.rawValue, with: query, at: region).map { data -> [String] in
            let count = data.children.count
            print("Found \(count) ADDS \(source.rawValue)")
            
            let raws = data.children.compactMap { item in
                item["raw_text"].element?.text
            }
            // remove possible duplicate entries
            return Array(Set(raws))
        }
    }
    
    private class func parse(data: Data, expecting dataSource: String) throws -> XMLIndexer {
        let response = SWXMLHash.parse(data)["response"]
    
        guard response["data_source"].element?.attribute(by: "name")?.text == dataSource else {
            throw Weather.error(msg: "No data")
        }
        
        let errors = response["errors"]
        guard errors.children.count == 0  else {
            let msgs = errors["error"].all.compactMap { $0.element?.text }
            throw Weather.error(msg: msgs.joined(separator: ", "))
        }
        
        let warnings = response["warnings"]
        if warnings.children.count > 0 {
            let msgs = warnings["warning"].all.compactMap { $0.element?.text }
            print("ADDS warning: \(msgs.joined())")
        }
        
        return response["data"]
    }
    
    private class func fetch(dataSource: String, with: [String: String] = [:], at region: WeatherRegion) -> Promise<XMLIndexer> {
        var params = [
            "dataSource": dataSource,
            "requestType": "retrieve",
            "format": "xml",
            "compression": "gzip",
            "minLat": String(region.minLat),
            "minLon": String(region.minLon),
            "maxLat": String(region.maxLat),
            "maxLon": String(region.maxLon)
        ]
        with.forEach { params[$0] = $1 }
        
        let host = UserDefaults.standard.string(forKey: "addsURL")!
        var components = URLComponents(string: host)!
        components.queryItems = params.map { name, value in URLQueryItem(name: name, value: value) }

        let rq = URLRequest(url: components.url!)
        print("Fetching ADDS data from \(components.url!)")
        return URLSession.shared.dataTask(.promise, with: rq).map { data, urlResponse -> XMLIndexer in
            let unzipped: Data = try {
                if data.isGzipped {
                    return try data.gunzipped()
                } else {
                    return data
                }
            }()
            
            
            return try self.parse(data: unzipped, expecting: dataSource)
        }
    }
}
