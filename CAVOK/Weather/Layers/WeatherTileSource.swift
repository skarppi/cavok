//
//  WeatherTileSource.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 08.03.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

open class WeatherTileSource : NSObject, MaplyTileSource {
    
    let frames: [HeatMap]
    
    let config: WeatherConfig
    
    init(frames: [HeatMap], config: WeatherConfig) {
        self.frames = frames
        self.config = config
    }
    
    /// @return Returns the minimum allowable zoom layer.  Ideally, this is 0.
    public func minZoom() -> Int32 {
        return Int32(config.zoom)
    }
    
    /// @return Returns the maximum allowable zoom layer.  Typically no more than 18,
    ///          but it depends on your implementation.
    public func maxZoom() -> Int32 {
        return Int32(config.zoom)
    }
    
    /** @brief Number of pixels on the side of a single tile (e.g. 128, 256).
     @details We use this for screen space calculation, so you don't have to
     return the exact number of pixels in the imageForTile calls.  It's
     easier if you do, though.
     @return Returns the number of pixels on a side for a single tile.
     */
    public func tileSize() -> Int32 {
        return Int32(config.tilesize)
    }
    
    /** @brief Can the given tile be fetched locally or do we need a network call?
     @details We may ask the tile source if the tile is local or needs to be fetched over the network.  This is a hint for the loader.  Don't return true in error, though, that'll hold up the paging.
     @return Return true for local tile sources or if you have the tile cached.
     */
    public func tileIsLocal(_ tileID: MaplyTileID, frame: Int32) -> Bool {
        return true
    }
    
    /** @brief The coordinate system the image pyramid is in.
     @details This is typically going to be MaplySphericalMercator
     with the web mercator extents.  That's what you'll get from
     OpenStreetMap and, often, MapBox.  In other cases it might
     be MaplyPlateCarree, which covers the whole earth.  Sometimes
     it might even be something unique of your own.
     */
    public func coordSys() -> MaplyCoordinateSystem {
        return config.coordSystem
    }
    
    /** @brief Check if we should even try to load a given tile.
     @details Tile pyramids can be sparse.  If you know where your pyramid is sparse, you can short circuit the fetch and simply return false here.
     @details If this method isn't filled in, everything defaults to true.
     @details tileID The tile we're asking about.
     @details bbox The bounding box of the tile we're asking about, for convenience.
     @return True if the tile is loadable, false if not.
     */
    public func validTile(_ tileID: MaplyTileID, bbox:MaplyBoundingBox) -> Bool {
        // flip y
        let y = (1<<tileID.level)-tileID.y-1
        
        if (tileID.x < config.ll.x || tileID.x >= config.ur.x || y >= config.ll.y || y < config.ur.y) {
            return false
        }
        return true
    }
    
    open func fetchTile(layer: MaplyQuadImageTilesLayer, tileID: MaplyTileID, frame:Int32) -> Data? {
        let bbox = tileID.bbox
//        print("Fetched frame \(frame) tile: \(tileID.level): (\(tileID.x),\(tileID.y)) ll = \(bbox.ll.deg.x) x \(bbox.ll.deg.y) ur = \(bbox.ur.deg.x) x \(bbox.ur.deg.y)")
        
        let localBox = config.coordSystem.geo(toLocalBox: bbox)
//        layer.bounds(forTile: tileID, bbox: &bbox)
        
        if let image = frames[Int(frame)].render(tileID, bbox: localBox, imageSize: config.tilesize) {
            let data = UIImagePNGRepresentation(image)
            //DebugTileSource.save(tileID, data: data)
            return data
        } else {
            return nil
        }
    }
    
    public func startFetchLayer(_ layer: Any, tile tileID: MaplyTileID) {
        DispatchQueue.global().async {
            if let layer = layer as? MaplyQuadImageTilesLayer {
                let frames = Int32(layer.imageDepth) - 1
                let images = (0...frames).flatMap { (frame) -> Data? in
                    self.fetchTile(layer: layer, tileID: tileID, frame:frame)
                }
                layer.loadedImages(MaplyImageTile(pnGorJPEGDataArray: images), forTile: tileID)
            }
        }
    }
    
    public func startFetchLayer(_ layer: Any, tile tileID: MaplyTileID, frame: Int32) {
        DispatchQueue.global().async {
            if let layer = layer as? MaplyQuadImageTilesLayer, let image = self.fetchTile(layer: layer, tileID: tileID, frame:frame) {
                layer.loadedImages(MaplyImageTile(pnGorJPEGData: image), forTile: tileID, frame: frame)
            }
        }
    }
}
