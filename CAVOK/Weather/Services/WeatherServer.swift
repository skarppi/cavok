//
//  WeatherService.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 21.10.12.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import RealmSwift

public class WeatherServer {

    let query = QueryService()

    // query stations available
    func queryStations(at region: WeatherRegion) async throws -> [Station] {

        async let adds = AddsService.fetchStations(at: region)
        async let aws = AwsService.fetchStations(at: region)

        let stations = try await (adds + aws)
            .filter { station -> Bool in
                return region.inRange(latitude: station.latitude, longitude: station.longitude)
                    && (station.hasMetar || station.hasTaf)
            }

        // remove duplicate identifiers
        var result: [String: Station] = [:]
        stations.forEach({ result[$0.identifier] = $0 })
        return Array(result.values)
    }

    // query and persist stations
    @MainActor func refreshStations() async throws -> [Station] {
        let stations = try await queryStations(at: WeatherRegion.load())
        let realm = try await Realm()

        try realm.write {
            realm.deleteAll()
            realm.add(stations)
        }
        return stations
    }

    @MainActor func refreshObservations() async throws {
        let region = WeatherRegion.load()

        async let addsMetars = AddsService.fetchObservations(.METAR, history: true, at: region)
        async let awsMetars = AwsService.fetchObservations(at: region)
        async let addsTafs = AddsService.fetchObservations(.TAF, history: false, at: region)

        let allMetars = try await (addsMetars + awsMetars)
        let allTafs = try await addsTafs

        let realm = try await Realm()
        let metars = allMetars.compactMap { metar in
            self.parseObservation(Metar(), raw: metar, realm: realm)
        }.sorted { metar1, metar2 in
            metar1.datetime < metar2.datetime
        }

        let tafs = allTafs.compactMap { raw in
            self.parseObservation(Taf(), raw: raw, realm: realm)
        }.sorted { taf1, taf2 in
            taf1.from < taf2.from
        }

        let oldMetars = realm.objects(Metar.self)
        let oldTafs = realm.objects(Taf.self)

        try realm.write {
            realm.delete(oldMetars)
            realm.delete(oldTafs)
            realm.add(metars, update: .all)
            realm.add(tafs, update: .all)
        }
    }

    private func parseObservation<T: Observation>(_ obs: T, raw: String, realm: Realm) -> T? {
        obs.parse(raw: raw)

        let stations = realm.objects(Station.self).filter("identifier == '\(obs.identifier)'")
        if stations.count == 1 {
            obs.station = stations[0]
            return obs
        } else {
            return nil
        }
    }
}
