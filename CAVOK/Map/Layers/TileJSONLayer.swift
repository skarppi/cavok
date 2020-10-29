//
//  JsonLayer.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 05.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class TileJSONLayer {
    
    let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]

    func load(url: String, globeVC: WhirlyGlobeViewController) {
        let tileInfo = MaplyRemoteTileInfoNew(baseURL: url,
                                              minZoom: 0,
                                              maxZoom: 22)
        tileInfo.cacheDir = cacheDir.absoluteString
        
        let sampleParams = MaplySamplingParams()
        sampleParams.coordSys = MaplySphericalMercator(webStandard: ())
        sampleParams.coverPoles = true
        sampleParams.edgeMatching = true
        sampleParams.minZoom = tileInfo.minZoom()
        sampleParams.maxZoom = tileInfo.maxZoom()
        sampleParams.singleLevel = false
        sampleParams.minImportance = 1024.0 * 1024.0 / 2.0
        
        MaplyQuadImageLoader(params: sampleParams, tileInfo: tileInfo, viewC: globeVC)
        
        print("Loaded map to \(cacheDir)")
    }
}
