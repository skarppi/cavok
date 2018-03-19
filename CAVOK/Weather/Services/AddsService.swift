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
        return fetch(dataSource: "stations", at: region).map { doc -> [Station] in
            print("Found \(doc["response"]["data"].children.count) ADDS stations")
            
            return doc["response"]["data"]["Station"].all.map { station in
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
        return fetch(dataSource: source.rawValue, with: query, at: region).map { doc -> [String] in
            let count = doc["response"]["data"].children.count
            print("Found \(count) ADDS \(source.rawValue)")
            guard count > 0 else {
                return []
            }
            
            let warnings = doc["response"]["warnings"]["warning"].all.flatMap { $0.element?.text }
            if warnings.count > 0 {
                print("ADDS warning: \(warnings.joined())")
            }
            
            let collection = doc["response"]["data"].children[0].element!.name
            let raws = doc["response"]["data"][collection].all.flatMap { item in
                item["raw_text"].element?.text
            }
            // remove possible duplicate entries
            return Array(Set(raws))
        }
    }
    
    private class func parse(data: Data, expecting dataSource: String) throws -> XMLIndexer {
        let doc = SWXMLHash.lazy(data)
        
        guard doc["response"]["data_source"].element?.attribute(by: "name")?.text == dataSource else {
            throw Weather.error(msg: "No data")
        }
        
        guard doc["response"]["errors"].children.count == 0  else {
            let errors = doc["response"]["errors"]["error"].all.flatMap { $0.element?.text }
            throw Weather.error(msg: errors.joined(separator: ", "))
        }
        
        return doc
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
