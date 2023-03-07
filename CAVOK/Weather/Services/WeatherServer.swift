//
//  WeatherService.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 21.10.12.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import RealmSwift

public class WeatherServer {

    static let query = QueryService()

    // query stations available
    func queryStations(at region: WeatherRegion) async throws -> [Station] {

        async let adds = AddsService.fetchStations(at: region)
        async let aws = AwsService.fetchStations(at: region)

        let stations = try await (adds + aws)
            .filter { station -> Bool in
                (station.hasMetar || station.hasTaf)
                    && region.inRange(latitude: station.latitude, longitude: station.longitude)
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

        async let addsMetars = AddsService.fetchObservations(.METAR, at: region, history: true)
        async let awsMetars = AwsService.fetchObservations(at: region)
        async let addsTafs = AddsService.fetchObservations(.TAF, at: region, history: false)

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

    private func latestMetar(station: Station) async throws -> String? {
        let region = WeatherRegion.load()
        switch station.source {
        case .aws:
            return try await AwsService.fetchLatestObservation(at: region, station: station.identifier)
        case .adds:
            return try await AddsService.fetchObservations(.METAR,
                                                           at: region,
                                                           station: station.identifier,
                                                           history: false).first
        }
    }

    @MainActor func fetchStation(station id: String) async throws -> Station? {
        let realm = try await Realm()
        return realm.object(ofType: Station.self, forPrimaryKey: id)?.freeze()
    }

    @MainActor func fetchLatest(station: Station) async throws -> Metar? {
        let realm = try await Realm()

        guard let metar = try await latestMetar(station: station) else {
            return nil
        }
        return parseObservation(Metar(), raw: metar, realm: realm)
    }

    private func parseObservation<T: Observation>(_ obs: T, raw: String, realm: Realm) -> T? {
        _ = obs.parse(raw: raw)

        guard let station = realm.object(ofType: Station.self, forPrimaryKey: obs.identifier) else {
            return nil
        }
        obs.station = station
        return obs
    }
}
