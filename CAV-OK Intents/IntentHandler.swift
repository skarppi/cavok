//
//  IntentHandler.swift
//  CAV-OK Intents
//
//  Created by Juho Kolehmainen on 9.2.2023.
//

import Intents
import RealmSwift

class IntentHandler: INExtension, ConfigurationIntentHandling {
    let query = QueryService()

    override init() {
        super.init()
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            fileURL: FileManager.cavok?.appending(path: "default.realm")
        )
    }

    func provideStationOptionsCollection(for intent: ConfigurationIntent, with completion: @escaping (INObjectCollection<SelectedStation>?, Error?) -> Void) {

        do {
            let stations = try query.getStation().map { station in
                return SelectedStation(
                    identifier: station.identifier,
                    display: station.name
                )
            }
            completion((INObjectCollection(items: stations)), nil)
        } catch {
            print(error)

            completion(nil, error)
        }
    }

    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.

        return self
    }

}
