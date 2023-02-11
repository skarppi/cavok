//
//  RealmService.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 9.2.2023.
//

import RealmSwift

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
}
