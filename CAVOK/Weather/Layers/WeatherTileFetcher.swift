//
//  WeatherTileFetcher.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 08.03.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

open class WeatherTileFetcher : MaplySimpleTileFetcher {
    
    let frames: [HeatMap]
    
    let config: WeatherConfig
    
    var loader: MaplyQuadImageLoader? = nil
    
    init?(frames: [HeatMap], config: WeatherConfig) {
        self.frames = frames
        self.config = config
        
        super.init(name: "", minZoom: Int32(config.minZoom), maxZoom: Int32(config.maxZoom))
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
    func validTile(_ tileID: MaplyTileID, bbox:MaplyBoundingBox) -> Bool {
        let y = (1<<tileID.level)-tileID.y-1 // flip
        let x = tileID.x
        
        let tile = config.tiles[Int(tileID.level)]
                
        if x >= tile.ur.x || (x + 1) <= tile.ll.x || (y + 1) <= tile.ur.y ||  y >= tile.ll.y {
//        if x >= tile.ur.x || (x + 1) <= tile.ll.x || y >= tile.ur.y || (y + 1) <= tile.ll.y {
            return false
        }
        
        // || y >= tile.ur.y ||  (y + 1) <= tile.ll.y
        
        print("Fetched frame tile: \(tileID.level): (\(tileID.x),\(tileID.y)) ll = \(bbox.ll.deg.x ?? 0) x \(bbox.ll.deg.y ?? 0) ur = \(bbox.ur.deg.x ?? 0) x \(bbox.ur.deg.y ?? 0)")

        
        return true
    }

    open override func data(forTile fetchInfo: Any, tileID: MaplyTileID) -> Any? {
//    open func fetchTile(layer: MaplyQuadImageTilesLayer, tileID: MaplyTileID, frame:Int32) -> Data? {
        let bbox = tileID.bboxFlip
        
        guard validTile(tileID, bbox:bbox) else {
            return nil
        }
        
        let frame = 0
        print("Fetching frame \(frame) tile: \(tileID.level): (\(tileID.x),\(tileID.y)) ll = \(bbox.ll.deg.x) x \(bbox.ll.deg.y) ur = \(bbox.ur.deg.x) x \(bbox.ur.deg.y)")
        
        let localBox = config.coordSystem.geo(toLocalBox: bbox)
//        layer.bounds(forTile: tileID, bbox: &bbox)
        
        if let image = frames[Int(frame)].render(tileID, bbox: localBox, imageSize: config.tilesize) {
            let data = image.pngData()
            //DebugTileSource.save(tileID, data: data)
            return data
        } else {
            return nil
        }
    }
//    
//    public func startFetchLayer(_ layer: Any, tile tileID: MaplyTileID) {
//        DispatchQueue.global().async {
//            if let layer = layer as? MaplyQuadImageTilesLayer {
//                let frames = Int32(layer.imageDepth) - 1
//                let images = (0...frames).compactMap { (frame) -> Data? in
//                    self.fetchTile(layer: layer, tileID: tileID, frame:frame)
//                }
//                layer.loadedImages(MaplyImageTile(pnGorJPEGDataArray: images)!, forTile: tileID)
//            }
//        }
//    }
//    
//    public func startFetchLayer(_ layer: Any, tile tileID: MaplyTileID, frame: Int32) {
//        DispatchQueue.global().async {
//            if let layer = layer as? MaplyQuadImageTilesLayer, let image = self.fetchTile(layer: layer, tileID: tileID, frame:frame) {
//                layer.loadedImages(MaplyImageTile(pnGorJPEGData: image)!, forTile: tileID, frame: frame)
//            }
//        }
//    }
}
