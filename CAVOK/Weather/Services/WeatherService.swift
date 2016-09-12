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
    public init() {
        WeatherRegion(minLat: 60, maxLat: 70, minLon: 20, maxLon: 30, radius: 1000).save()
    }
    
    // query stations available
    func queryStations() -> Promise<[Station]> {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        return firstly {
            //when(fulfilled:
                AddsService.fetchStations()
                //AwsService.fetchStations()
            //)
        }.then { (adds) -> [Station] in
            let region = WeatherRegion.load()
            return adds.filter { station -> Bool in
                return region!.inRange(latitude: station.latitude, longitude: station.longitude) && (station.hasMetar || station.hasTaf)

            }
        }.always {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    // query and persist stations
    func refreshStations() -> Promise<[Station]> {
        return queryStations().then { stations -> [Station] in
            let realm = try! Realm()
            let oldStations = realm.allObjects(ofType: Station.self)
            let oldMetars = realm.allObjects(ofType: Metar.self)
            
            try realm.write {
                realm.delete(oldStations)
                realm.delete(oldMetars)
                realm.add(stations)
            }
            
            return stations
        }
    }
    
    func refreshObservations() -> Promise<[Observation]> {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        return firstly {
            when(fulfilled:
                AddsService.fetchObservations(.METAR),
                AddsService.fetchObservations(.TAF)
            )
        }.then { addsMetars, addsTafs -> [Observation] in
            let realm = try! Realm()
            let oldMetars = realm.allObjects(ofType: Metar.self)
            let oldTafs = realm.allObjects(ofType: Taf.self)
            
            let metars: [Observation] = (addsMetars).flatMap { metar in
                self.parseObservation(Metar(), raw: metar, realm: realm)
            }
            let tafs: [Observation] = addsTafs.flatMap { taf in
                self.parseObservation(Taf(), raw: taf, realm: realm)
            }
            let observations = metars + tafs
            try realm.write {
                realm.delete(oldMetars)
                realm.delete(oldTafs)
                realm.add(metars + tafs, update: true)
            }
            return observations
        }.always { observations in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            return observations
        }
    }
    
    private func parseObservation<T: Observation>(_ obs: T, raw: String, realm: Realm) -> T? {
        obs.parse(raw: raw)
        
        let stations = realm.allObjects(ofType: Station.self).filter(using: "identifier == '\(obs.identifier)'")
        if stations.count == 1 {
            obs.station = stations[0]
            return obs
        } else {
            //NSLog("Station '%@' returned %tu items", identifier, stations.count);
            return nil
        }
    }
    
    // MARK: - Query cached data
    
    func getStationCount() -> Int {
        let realm = try! Realm()
        return realm.allObjects(ofType: Station.self).count
    }
    
    func observations(_ type: Observation.Type) -> [Observation] {
        let realm = try! Realm()
        let observations = realm.allObjects(ofType: type)
        return Array(observations.sorted(onProperty: "datetime"))
    }
    
    func observations(_ from: Date, minutes: Int, type:Observation.Type) -> [Observation] {
        let realm = try! Realm()
        let observations = realm.allObjects(ofType: type)
        
        let to = Calendar.current.date(byAdding: .minute, value: minutes, to: from)
        
        let filtered = observations.filter(using: NSPredicate(format: "datetime >= \(from) and datetime < \(to)"))
        print("filtered \(filtered.count) \(type.className()) between \(from) and  \(to)")
        return Array(filtered.sorted(onProperty: "datetime"))
    }
    
}
