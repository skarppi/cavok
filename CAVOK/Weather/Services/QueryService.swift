//
//  RealmService.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 9.2.2023.
//

import RealmSwift
import CoreLocation

public class QueryService {

    func getStation() throws -> [Station] {
        let realm = try Realm()
        return realm.objects(Station.self)
            .sorted(byKeyPath: "identifier")
            .map { $0.freeze() }
    }

    func getStationCount() throws -> Int {
        let realm = try Realm()
        return realm.objects(Station.self).count
    }

    private func fetch<Element: Observation>(type: Element.Type, sortKey: String, filter: String?) throws -> [Element] {
        let realm = try Realm()

        let objects = realm.objects(type)

        let filtered: Results<Element>
        if let filter = filter {
            filtered = objects.filter("identifier == '\(filter)'")
        } else {
            filtered = objects
        }

        return filtered
            .sorted(byKeyPath: sortKey)
            .map { $0.freeze() }
    }

    func observations(for identifier: String? = nil) throws -> Observations {
        return Observations(metars: try fetch(type: Metar.self, sortKey: "datetime", filter: identifier),
                            tafs: try fetch(type: Taf.self, sortKey: "from", filter: identifier))
    }

    func nearby(location: CLLocationCoordinate2D) throws -> [Metar] {
        let realm = try Realm()

        let metars = try realm.findNearby(type: Metar.self,
                                          origin: location,
                                          radius: 100000,
                                          sortAscending: true,
                                          distinct: (by: "identifier", sorted: "datetime", ascending: false),
                                          distanceKey: \Metar.distance,
                                          latitudeKey: \Metar.station?.latitude,
                                          longitudeKey: \Metar.station?.longitude)
        return metars
    }

    func favorites(location: CLLocationCoordinate2D?) throws -> [Metar] {
        let realm = try Realm()
        let metars = realm.objects(Metar.self)
            .sorted(byKeyPath: "datetime", ascending: false)
            .distinct(by: ["station.identifier"])
            .where { $0.station.favorite == true }
            .sorted(byKeyPath: "station.identifier")

        guard let location = location else {
            return Array(metars)
        }

        return metars.addDistance(center: location,
                                  distanceKey: \Metar.distance,
                                  latitudeKey: \Metar.station?.latitude,
                                  longitudeKey: \Metar.station?.longitude)
    }

    @MainActor func favorite(station source: Station) throws {
        let realm = try Realm()
        guard let station = realm.object(ofType: Station.self, forPrimaryKey: source.identifier) else {
            return
        }

        try realm.write {
            station.favorite = !station.favorite
        }
    }

    @MainActor func fetchObservation(observation: Observation) throws -> Observation {
        let realm = try Realm()

        return realm.object(ofType: Observation.self, forPrimaryKey: observation.raw) ?? observation
    }

}
