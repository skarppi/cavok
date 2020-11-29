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
    
    func load(url: String, globeVC: WhirlyGlobeViewController) -> MaplyQuadImageLoader? {
        let tileInfo = MaplyRemoteTileInfoNew(baseURL: url,
                                              minZoom: 0,
                                              maxZoom: 22)
        tileInfo.cacheDir = "\(cacheDir.absoluteString)\(abs(url.hash))"
        
        let sampleParams = MaplySamplingParams()
        sampleParams.coordSys = MaplySphericalMercator(webStandard: ())
        sampleParams.coverPoles = true
        sampleParams.edgeMatching = true
        sampleParams.minZoom = tileInfo.minZoom()
        sampleParams.maxZoom = tileInfo.maxZoom()
        sampleParams.singleLevel = true
        sampleParams.minImportance = 1024.0 * 1024.0 / 2.0
        
        guard let imageLoader = MaplyQuadImageLoader(params: sampleParams, tileInfo: tileInfo, viewC: globeVC) else {
            return nil
        }
        imageLoader.baseDrawPriority = kMaplyImageLayerDrawPriorityDefault
        
        print("Loaded map to \(tileInfo.cacheDir!)")
        return imageLoader
    }
}
