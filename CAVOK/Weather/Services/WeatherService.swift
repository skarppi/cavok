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
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        return firstly {
            when(fulfilled:
                AddsService.fetchStations(at: region),
                 AwsService.fetchStations(at: region)
            )
        }.map { adds, aws in
            return (adds + aws).filter { station -> Bool in
                return region.inRange(latitude: station.latitude, longitude: station.longitude) && (station.hasMetar || station.hasTaf)

            }
        }.map { stations in
            // remove duplicate identifiers
            var result: [String: Station] = [:]
            stations.forEach({ result[$0.identifier] = $0 })
            return Array(result.values)
            
        }.ensure {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    // query and persist stations
    func refreshStations() -> Promise<[Station]> {
        guard let region = WeatherRegion.load() else {
            return Promise(error: Weather.error(msg: "Region not set"))
        }
        
        return queryStations(at: region).map { stations -> [Station] in
            let realm = try! Realm()
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
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        return firstly {
            when(fulfilled:
                AddsService.fetchObservations(.METAR, history: true, at: region),
                 AddsService.fetchObservations(.TAF, history: false, at: region),
                 AwsService.fetchObservations(at: region)
            )
        }.map { addsMetars, addsTafs, awsMetars in
            let realm = try! Realm()
            let oldMetars = realm.objects(Metar.self)
            let oldTafs = realm.objects(Taf.self)
            
            let metars = (addsMetars + awsMetars).compactMap { metar in
                self.parseObservation(Metar(), raw: metar, realm: realm)
            }.sorted { a, b in
                a.datetime < b.datetime
            }
            let tafs = addsTafs.compactMap { taf in
                self.parseObservation(Taf(), raw: taf, realm: realm)
            }.sorted { a, b in
                a.from < b.from
            }
            try realm.write {
                realm.delete(oldMetars)
                realm.delete(oldTafs)
                realm.add(metars, update: .all)
                realm.add(tafs, update: .all)
            }
            return Observations(metars: metars, tafs: tafs)
        }.ensure {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
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
        let realm = try! Realm()
        return realm.objects(Station.self).count
    }
    
    func observations() -> Observations {
        let realm = try! Realm()
        
        let metars = realm.objects(Metar.self).sorted(byKeyPath: "datetime")
        let tafs = realm.objects(Taf.self).sorted(byKeyPath: "from")

        return Observations(metars: Array(metars), tafs: Array(tafs))
    }
    
    func observations(for identifier: String) -> Observations {
        let realm = try! Realm()
        
        let metars = realm.objects(Metar.self).filter("identifier == '\(identifier)'").sorted(byKeyPath: "datetime")
        let tafs = realm.objects(Taf.self).filter("identifier == '\(identifier)'").sorted(byKeyPath: "from")
        
        return Observations(metars: Array(metars), tafs: Array(tafs))
    }
}
