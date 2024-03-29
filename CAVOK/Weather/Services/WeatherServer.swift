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
        async let atis = AtisService.fetchStations(at: region)

        let stations = try await (adds + aws + atis)
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

        // preserve favorites
        let favorites = try WeatherServer.query.favorites().map { $0.identifier }

        try realm.write {
            realm.deleteAll()
            realm.add(stations.map { station in
                station.favorite = favorites.contains(station.identifier)
                return station
            })
        }
        return stations
    }

    @MainActor func refreshObservations() async throws {
        let region = WeatherRegion.load()

        async let adds = AddsService.fetchObservations(.METAR, at: region, history: true)
        async let aws = AwsService.fetchObservations(at: region)
        async let atis = AtisService.fetchObservations(at: region)

        let allMetars = try await (adds + aws + atis)
        let allTafs = try await adds

        let realm = try await Realm()
        let metars = allMetars.filter( { $0.isKind(of: Metar.self) }).compactMap { metar in
            enrichObservation(metar, realm: realm)
        }

        let tafs = allTafs.filter({$0.isKind(of: Taf.self)}).compactMap { taf in
            enrichObservation(taf, realm: realm)
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
                                                           history: false).first?.raw
        case .atis:
            return try await AtisService.fetchLatestObservation(at: region, station: station.identifier)
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
        return enrichObservation(Metar().parse(raw: metar), realm: realm)
    }

    private func enrichObservation<T: Observation>(_ obs: T, realm: Realm) -> T? {
        guard let station = realm.object(ofType: Station.self, forPrimaryKey: obs.identifier) else {
            return nil
        }
        obs.station = station
        return obs
    }
}
