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
    
    class func fetchStations() -> Promise<[Station]> {
        return fetch(dataSource: "stations").then { doc -> [Station] in
            NSLog("Found \(doc["response"]["data"].children.count) ADDS stations")
            
            return doc["response"]["data"]["Station"].all.map { station in
                Station(
                    identifier: station["station_id"].element!.text!,
                    name: station["site"].element!.text!,
                    latitude: Float(station["latitude"].element!.text!)!,
                    longitude: Float(station["longitude"].element!.text!)!,
                    elevation: Float(station["elevation_m"].element!.text!)!,
                    hasMetar: station["site_type"]["METAR"].element != nil,
                    hasTaf: station["site_type"]["TAF"].element != nil
                )
            }
        }
    }
    
    class func fetchObservations(_ source: AddsSource) -> Promise<[String]> {
        let query = [
            "hoursBeforeNow": "3",
            "mostRecentForEachStation": "false",
            "fields": "raw_text"
        ]
        return fetch(dataSource: String(source.rawValue), with: query).then { doc -> [String] in
            let count = doc["response"]["data"].children.count
            print("Found \(count) ADDS \(source.rawValue)")
            if count == 0 {
                return []
            }
            
            let name = doc["response"]["data"].children[0].element!.name
            return doc["response"]["data"][name].all.flatMap { item in
                item["raw_text"].element?.text
            }
        }
    }
    
    private class func parse(data: Data, expecting dataSource: String) throws -> XMLIndexer {
        let doc = SWXMLHash.lazy(data)
        
        if doc["response"]["data_source"].element?.attribute(by: "name")?.text != dataSource {
            throw Weather.error(msg: "No data")
            
        } else if doc["response"]["errors"].children.count > 0 {
            let errors = doc["response"]["errors"]["error"].all.flatMap { $0.element?.text }
            throw Weather.error(msg: errors.joined(separator: ", "))
        }
        return doc
    }
    
    private class func fetch(dataSource: String, with: [String: String] = [:]) -> Promise<XMLIndexer> {
        if let b = WeatherRegion.load() {
            
            var params = [
                "dataSource": dataSource,
                "requestType": "retrieve",
                "format": "xml",
                "compression": "gzip",
                "minLat": String(b.minLat),
                "minLon": String(b.minLon),
                "maxLat": String(b.maxLat),
                "maxLon": String(b.maxLon)
            ]
            with.forEach { params[$0] = $1 }
            
            let host = UserDefaults.standard.string(forKey: "addsURL")!
            var components = URLComponents(string: host)!
            components.queryItems = params.map { name, value in URLQueryItem(name: name, value: value) }

            let rq = URLRequest(url: components.url!)
            NSLog("Fetching ADDS data from \(components.url!)")
            
            return URLSession.shared.dataTask(with: rq).then { data -> XMLIndexer in
                let unzipped: Data = try {
                    if data.isGzipped {
                        return try data.gunzipped()
                    } else {
                        return data
                    }
                }()
                
                
                return try self.parse(data: unzipped, expecting: dataSource)
            }
        } else {
            return Promise(error: Weather.error(msg: "Region not set"))
        }
    }
}
