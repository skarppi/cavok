//
//  CustomMaplySimpleTileFetcher.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 2.1.2021.
//

import Foundation

// Encapsulates a single tile load request
struct WeatherTileFetchInfo {
    var tileID: MaplyTileID
    var frame: Int
}

// Internal object used by the QuadImageLoader to generate tile load info
class WeatherTileInfo: NSObject, MaplyTileInfoNew {
    private let config: WeatherConfig
    private var frame: Int

    init(config: WeatherConfig, frame: Int) {
        self.config = config
        self.frame = frame
    }

    func fetchInfo(forTile tileID: MaplyTileID, flipY: Bool) -> Any? {
        if tileID.validTile(config: config) {
            return WeatherTileFetchInfo(tileID: tileID, frame: frame)
        } else {
            return nil
        }

    }

    func minZoom() -> Int32 {
        Int32(config.minZoom)
    }

    func maxZoom() -> Int32 {
        Int32(config.maxZoom)
    }
}

// Similar to SimpleTileFetcher but supports frames
class WeatherSimpleTileFetcher: NSObject, MaplyTileFetcher {

    // Dispatch queue the data fetcher is doing its work on
    let queue = OperationQueue()

    init(name: String) {
        super.init()
        queue.name = name
        queue.maxConcurrentOperationCount = 5
    }

    func startTileFetches(_ requests: [MaplyTileFetchRequest]) {
        requests.forEach { req in
            queue.addOperation { self.startTileFetch(req) }
        }
    }

    func startTileFetch(_ request: MaplyTileFetchRequest) {
        if let result = tryTileFetch(request) {
            request.success?(request, result)
        } else {
            request.failure?(request, Weather.error(msg: "Failed to fetch tile \(request.tileID)"))
        }
    }

    func tryTileFetch(_ request: MaplyTileFetchRequest) -> Data? {
        guard let info = request.fetchInfo as? WeatherTileFetchInfo else { return nil; }

        return self.data(forTile: info, tileID: info.tileID)
    }

    func updateTileFetch(_ fetchID: Any, priority: Int32, importance: Double) -> Any? {
        return nil
    }

    func cancelTileFetches(_ requestRets: [Any]) {
    }

    // Name used for debugging
    func name() -> String {
        queue.name ?? "fetcher"
    }

    /// Override dataForTile:tileID: to return your own data for a given tile.
    /// The fetchInfo can be a custom object (if you set it up that way) or
    /// you can just use the tileID argument.
    /// You'll be called on the dispatch queue.
    /// You can return either an NSData or a MaplyLoaderReturn
    func data(forTile: WeatherTileFetchInfo, tileID: MaplyTileID) -> Data? {
        nil
    }

    /// Override the shutdown method.
    /// Call the superclass shutdown method *first* and then run your own shutdown.
    func shutdown() {
        queue.cancelAllOperations()
    }
}
