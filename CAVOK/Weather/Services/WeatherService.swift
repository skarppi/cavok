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
    private func queryStations() -> Promise<[Station]> {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        return firstly {
            when(fulfilled:
                AddsService.fetchStations(),
                AwsService.fetchStations()
            )
        }.then { (adds, aws) -> [Station] in
            guard let region = WeatherRegion.load() else {
                return []
            }
            
            return (adds + aws).filter { station -> Bool in
                return region.inRange(latitude: station.latitude, longitude: station.longitude) && (station.hasMetar || station.hasTaf)

            }
        }.always {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    // query and persist stations
    func refreshStations() -> Promise<[Station]> {
        return queryStations().then { stations -> [Station] in
            let realm = try! Realm()
            try realm.write {
                realm.deleteAll()
                realm.add(stations)
            }
            return stations
        }
    }
    
    func refreshObservations() -> Promise<Observations> {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        return firstly {
            when(fulfilled:
                AddsService.fetchObservations(.METAR, history: true),
                 AddsService.fetchObservations(.TAF, history: false),
                 AwsService.fetchObservations()
            )
        }.then { addsMetars, addsTafs, awsMetars -> Observations in
            let realm = try! Realm()
            let oldMetars = realm.objects(Metar.self)
            let oldTafs = realm.objects(Taf.self)
            
            let metars = (addsMetars + awsMetars).flatMap { metar in
                self.parseObservation(Metar(), raw: metar, realm: realm)
            }.sorted { a, b in
                a.datetime < b.datetime
            }
            let tafs = addsTafs.flatMap { taf in
                self.parseObservation(Taf(), raw: taf, realm: realm)
            }.sorted { a, b in
                a.from < b.from
            }
            try realm.write {
                realm.delete(oldMetars)
                realm.delete(oldTafs)
                realm.add(metars, update: true)
                realm.add(tafs, update: true)
            }
            return Observations(metars: metars, tafs: tafs)
        }.always { observations in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            return observations
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
        
        let metars = realm.objects(Metar.self).sorted(byProperty: "datetime")
        let tafs = realm.objects(Taf.self).sorted(byProperty: "from")

        return Observations(metars: Array(metars), tafs: Array(tafs))
    }
}
