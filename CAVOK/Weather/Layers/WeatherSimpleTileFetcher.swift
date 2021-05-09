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

// A single tile that we're aware of
struct TileInfo: Hashable {
    static func == (lhs: TileInfo, rhs: TileInfo) -> Bool {
        lhs.request == rhs.request
            && lhs.priority == rhs.priority
            && lhs.importance == rhs.importance
            && lhs.fetchInfo.tileID.x == rhs.fetchInfo.tileID.x
            && lhs.fetchInfo.tileID.y == rhs.fetchInfo.tileID.y
            && lhs.fetchInfo.tileID.level == rhs.fetchInfo.tileID.level
            && lhs.fetchInfo.frame == rhs.fetchInfo.frame
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(request)
    }

    // Priority before importance
    var priority: Int32
    // Importance of this tile request as passed in by the fetch request
    var importance: Float
    // The request as it came from outside the tile fetcher
    var request: MaplyTileFetchRequest
    // Specific fetchInfo from the fetch request.
    var fetchInfo: WeatherTileFetchInfo

    //    /// Comparison based on importance, tile source, then x,y,level
    //    bool operator < (const TileInfo &that) const
    //    {
    //        if (this->priority == that.priority) {
    //            if (this->importance == that.importance) {
    //                return this->request < that.request;
    //            }
    //            return this->importance < that.importance;
    //        }
    //        return this->priority > that.priority;
    //    }
}

// Similar to SimpleTileFetcher but supports frames
open class WeatherSimpleTileFetcher: NSObject, MaplyTileFetcher {

    /// Set by default.  We won't every return an error on failing to load.  Useful for sparse data sets
    private var neverFail = false

    private var active = false
    private var loadScheduled = false

    // Tiles sorted by importance
    private var toLoad: Set<TileInfo> = []

    // Tiles sorted by fetch request
    private var tilesByFetchRequest = [MaplyTileFetchRequest: TileInfo]()

    // Dispatch queue the data fetcher is doing its work on
    private var queue: DispatchQueue!

    init(name: String) {
        queue = DispatchQueue(label: name)
        super.init()

        active = true
    }

    public func startTileFetches(_ requests: [MaplyTileFetchRequest]) {
        guard active else {
            return
        }

        queue.async {
            requests.forEach { req in
                let info = TileInfo(priority: req.priority, importance: req.importance, request: req, fetchInfo: req.fetchInfo as! WeatherTileFetchInfo)
                self.tilesByFetchRequest[req] = info
                self.toLoad.insert(info)
            }

            if !self.loadScheduled {
                self.loadScheduled = true
                self.updateLoading()
            }

        }
    }

    public func updateTileFetch(_ request: Any, priority: Int32, importance: Double) -> Any? {
        guard active else {
            return Optional<Any>.none as Any
        }

        queue.async {
            if let req = request as? MaplyTileFetchRequest, var tile = self.tilesByFetchRequest[req] {
                self.toLoad.remove(tile)
                tile.priority = req.priority
                tile.importance = req.importance
                self.toLoad.insert(tile)
            }
        }

        return request
    }

    public func cancelTileFetches(_ requests: [Any]) {
        guard active else {
            return
        }

        queue.async {
            requests.forEach { request in
                if let req = request as? MaplyTileFetchRequest, let tile = self.tilesByFetchRequest.removeValue(forKey: req) {
                    self.toLoad.remove(tile)
                }
            }
        }
    }

    func updateLoading() {
        loadScheduled = false

        guard active else {
            return
        }

        if let tile = toLoad.first {
            let info = tile.fetchInfo

            // Do the callback on a background queue
            // Because the parsing might take a while
            DispatchQueue.global(qos: .background).sync {
                let tileData = self.data(forTile: info, tileID: info.tileID)
                if tileData != nil || self.neverFail {
                    tile.request.success?(tile.request, tileData as Any)
                } else {
                    tile.request.failure?(tile.request, Weather.error(msg: "Failed to fetch tile"))
                }

                self.queue?.async {
                    self.updateLoading()
                }
            }

            // Done with the tile, so take it out of here
            toLoad.remove(tile)
            tilesByFetchRequest.removeValue(forKey: tile.request)
        }
    }

    // Name used for debugging
    public func name() -> String {
        queue?.label ?? ""
    }

    /// Override dataForTile:tileID: to return your own data for a given tile.
    /// The fetchInfo can be a custom object (if you set it up that way) or
    /// you can just use the tileID argument.
    /// You'll be called on the dispatch queue.
    /// You can return either an NSData or a MaplyLoaderReturn
    func data(forTile fetchInfo: Any, tileID: MaplyTileID) -> Any? {
        ""
    }

    /// Override the shutdown method.
    /// Call the superclass shutdown method *first* and then run your own shutdown.
    public func shutdown() {
        active = false

        queue.async {
            // Execute an empty task and wait for it to return
            // This drains the queue
        }
        queue = nil
    }
}
