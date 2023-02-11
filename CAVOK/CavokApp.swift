//
//  CavokApp.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 1.6.2021.
//

import SwiftUI
import RealmSwift

@main
struct CavokApp: SwiftUI.App {
    @Environment(\.scenePhase) var scenePhase

    init() {
        // Override point for customization after application launch.

        if let url = Bundle.main.url(forResource: "CAVOK", withExtension: "plist"),
           let plist = NSDictionary(contentsOf: url) as? [String: Any] {
            UserDefaults.cavok?.register(defaults: plist)
        }

        initRealms()

        Messages.setup()
    }

    var body: some Scene {
        WindowGroup {
            MapView()
        }.onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .background:
                print("Writing settings to disk -> background")
                UserDefaults.cavok?.synchronize()
            case .inactive :
                print("App State: inactive")
            case .active :
                print("App State: active")
            default:
                print("App State: unknown")
            }
        }
    }
}

func initRealms() {
    let config = Realm.Configuration(
        fileURL: FileManager.cavok?.appending(path: "default.realm"),

        // Set the new schema version. This must be greater than the previously used
        // version (if you've never set a schema version before, the version is 0).
        schemaVersion: 0,

        // Set the block which will be called automatically when opening a Realm with
        // a schema version lower than the one set above
        migrationBlock: { _, oldSchemaVersion in
            // We haven’t migrated anything yet, so oldSchemaVersion == 0
            if oldSchemaVersion < 1 {
                // Nothing to do!
                // Realm will automatically detect new properties and removed properties
                // And will update the schema on disk automatically
            }
        }
    )

    // Tell Realm to use this new configuration object for the default Realm
    Realm.Configuration.defaultConfiguration = config

    // Now that we've told Realm how to handle the schema change, opening the file
    // will automatically perform the migration
    do {
        let realm = try Realm()
        print(realm.configuration.fileURL ?? "No realm file")
    } catch {
        let realmURL = config.fileURL!
        [
            realmURL,
            realmURL.appendingPathExtension("lock"),
            realmURL.appendingPathExtension("note"),
            realmURL.appendingPathExtension("management")
        ].forEach { url in
            try? FileManager.default.removeItem(at: url)
        }
        do {
            let realm = try Realm()
            print(realm.configuration.fileURL ?? "No realm file")
        } catch let error {
            print(error)
        }
    }
}
