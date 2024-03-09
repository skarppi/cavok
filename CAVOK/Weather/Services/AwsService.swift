//
//  AwsService.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 22/06/2015.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import SwiftyJSON

enum AwsSource: String {
    case STATION = "awsStationsURL", METAR = "awsMetarsURL"
}

public class AwsService {

    class func fetchStations(at region: WeatherRegion) async throws -> [Station] {
        let json = try await fetch(dataSource: AwsSource.STATION, at: region)
        let stations = json?.dictionaryValue.values.map { station -> Station in
            return Station(
                identifier: station["p1"].stringValue.subString(0, length: 4),
                name: station["coordinate"].stringValue,
                latitude: station["lat"].floatValue,
                longitude: station["lon"].floatValue,
                elevation: 0,
                source: .aws,
                hasMetar: true,
                hasTaf: false
            )
        } ?? []

        print("Found \(stations.count) AWS stations")
        return stations
    }

    class func fetchLatestObservation(at region: WeatherRegion, station: String) async throws -> String? {
        let json = try await fetch(dataSource: AwsSource.STATION, at: region)
        return json?.dictionaryValue.values
            .first(where: { sta in sta["p1"].stringValue.subString(0, length: 4) == station })
            .map { sta in sta["p1"].stringValue }
    }

    class func fetchObservations(at region: WeatherRegion) async throws -> [Metar] {
        let json = try await fetch(dataSource: AwsSource.METAR, at: region)
        let raws = json?["data"]["aws"]["finland"].dictionaryValue.values.flatMap { obs -> [String] in
            return [obs["message"].stringValue] + obs["old_messages"].arrayValue.map { $0.stringValue }
        } ?? []

        print("Found \(raws.count) AWS metars")

        return raws.map { raw in
            Metar().parse(raw: raw)
        }
    }

    private class func fetch(dataSource: AwsSource, at region: WeatherRegion) async throws -> JSON? {
        guard region.maxLat > 59 && region.minLat < 70 && region.maxLon > 19 && region.minLon < 30 else {
            print("Skipping AWS because out of bounds.")
            return nil
        }

        let url = URL(string: UserDefaults.cavok!.string(forKey: dataSource.rawValue)!.removingPercentEncoding!)!

        print("Fetching AWS data from \(url)")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSON(data: data)
    }
}
