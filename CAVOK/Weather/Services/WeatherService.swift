//
//  WeatherService.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 21.10.12.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import RealmSwift
import PromiseKit

public class WeatherServer {

    // query stations available
    func queryStations(at region: WeatherRegion) -> Promise<[Station]> {
        return firstly {
            when(fulfilled:
                    AddsService.fetchStations(at: region),
                 AwsService.fetchStations(at: region)
            )
        }.map { adds, aws in
            return (adds + aws).filter { station -> Bool in
                return region.inRange(latitude: station.latitude, longitude: station.longitude)
                    && (station.hasMetar || station.hasTaf)

            }
        }.map { stations in
            // remove duplicate identifiers
            var result: [String: Station] = [:]
            stations.forEach({ result[$0.identifier] = $0 })
            return Array(result.values)
        }
    }

    // query and persist stations
    func refreshStations() -> Promise<[Station]> {
        guard let region = WeatherRegion.load() else {
            return Promise(error: Weather.error(msg: "Region not set"))
        }

        return queryStations(at: region).map { stations -> [Station] in
            let realm = try Realm()
            try realm.write {
                realm.deleteAll()
                realm.add(stations)
            }
            return stations
        }
    }

    func refreshObservations() -> Promise<Observations> {
        guard let region = WeatherRegion.load() else {
            return Promise(error: Weather.error(msg: "Region not set"))
        }

        return firstly {
            when(fulfilled:
                    AddsService.fetchObservations(.METAR, history: true, at: region),
                 AddsService.fetchObservations(.TAF, history: false, at: region),
                 AwsService.fetchObservations(at: region)
            )
        }.map { addsMetars, addsTafs, awsMetars in
            let realm = try Realm()
            let oldMetars = realm.objects(Metar.self)
            let oldTafs = realm.objects(Taf.self)

            let metars = (addsMetars + awsMetars).compactMap { metar in
                self.parseObservation(Metar(), raw: metar, realm: realm)
            }.sorted { metar1, metar2 in
                metar1.datetime < metar2.datetime
            }
            let tafs = addsTafs.compactMap { taf in
                self.parseObservation(Taf(), raw: taf, realm: realm)
            }.sorted { taf1, taf2 in
                taf1.from < taf2.from
            }
            try realm.write {
                realm.delete(oldMetars)
                realm.delete(oldTafs)
                realm.add(metars, update: .all)
                realm.add(tafs, update: .all)
            }
            return Observations(metars: metars, tafs: tafs)
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

    // MARK: - Query cached data

    func getStationCount() -> Int {
        do {
            let realm = try Realm()
            return realm.objects(Station.self).count
        } catch let error {
            Messages.show(error: error)
            return 0
        }
    }

    private func fetch<Element: Observation>(type: Element.Type, sortKey: String, filter: String?) -> [Element] {
        do {
            let realm = try Realm()

            let objects = realm.objects(type)

            let filtered: Results<Element>
            if let filter = filter {
                filtered = objects.filter("identifier == '\(filter)'")
            } else {
                filtered = objects
            }

            return Array(filtered.sorted(byKeyPath: sortKey))
        } catch let error {
            Messages.show(error: error)
            return Array()
        }
    }

    func observations(for identifier: String? = nil) -> Observations {
        return Observations(metars: fetch(type: Metar.self, sortKey: "datetime", filter: identifier),
                            tafs: fetch(type: Taf.self, sortKey: "from", filter: identifier))
    }
}
