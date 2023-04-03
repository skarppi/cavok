//
//  WeatherTileFetcher.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 08.03.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class WeatherTileFetcher: WeatherSimpleTileFetcher {

    let frames: [HeatMap]

    let config: WeatherConfig

    init?(frames: [HeatMap], config: WeatherConfig) {
        self.frames = frames
        self.config = config

        super.init(name: "weather")
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

    override func data(forTile info: WeatherTileFetchInfo, tileID: MaplyTileID) -> Data? {
        let bbox = tileID.bboxFlip

        guard tileID.validTile(config: config) else {
            return nil
        }

        let index = info.frame

        let frame = frames[index]

        let localBox = config.coordSystem.geo(toLocalBox: bbox)

        if let image = frame.render(tileID, bbox: localBox, imageSize: config.tilesize) {
            let data = image.pngData()
            // DebugTileSource.save(tileID, data: data)
            return data
        } else {
            return nil
        }
    }
}
