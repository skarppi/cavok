//
//  AwsService.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 22/06/2015.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import PMKFoundation
import PromiseKit
import SwiftyJSON

enum AwsSource: String {
    case STATION = "awsStationsURL", METAR = "awsMetarsURL"
}

public class AwsService {
    
    class func fetchStations() -> Promise<[Station]> {
        return fetch(dataSource: AwsSource.STATION).then { json -> [Station] in
            let stations = json?.dictionaryValue.values.map { station -> Station in
                return Station(
                    identifier: station["p1"].stringValue.subString(0, length: 4),
                    name: station["coordinate"].stringValue,
                    latitude: station["lat"].floatValue,
                    longitude: station["lon"].floatValue,
                    elevation: 0,
                    hasMetar: true,
                    hasTaf: false
                )
            } ?? []
            
            NSLog("Found \(stations.count) AWS stations")
            return stations
        }
    }
    
    class func fetchObservations() -> Promise<[String]> {
        return fetch(dataSource: AwsSource.METAR).then { json -> [String] in
            let raws = json?["data"]["aws"]["finland"].dictionaryValue.values.flatMap { obs -> [String] in
                return [obs["message"].stringValue] + obs["old_messages"].arrayValue.map { $0.stringValue }
            } ?? []
            
            print("Found \(raws.count) AWS metars")
            
            // remove possible duplicate entries
            return raws//Array(Set(raws))
        }
    }
    
    private class func fetch(dataSource: AwsSource) -> Promise<JSON?> {
        guard let b = WeatherRegion.load() else {
            return Promise(error: Weather.error(msg: "Region not set"))
        }
        
        guard b.maxLat > 59 && b.minLat < 70 && b.maxLon > 19 && b.minLon < 30 else {
            print("Skipping AWS because out of bounds.")
            return Promise(value: nil)
        }
            
        let url = URL(string: UserDefaults.standard.string(forKey: dataSource.rawValue)!)!
        
        print("Fetching AWS data from \(url)")
        let rq = URLRequest(url: url)
        return URLSession.shared.dataTask(with: rq).then { data -> JSON in
            return JSON(data: data)
        }
    }
}
