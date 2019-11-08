//
//  JsonLayer.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 05.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import PromiseKit
import PMKFoundation
import SwiftyJSON

class TileJSONLayer {
    
    let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]

    func load(url: URL) -> Promise<MaplyViewControllerLayer> {
        let rq = URLRequest(url: url)
        
        return URLSession.shared.dataTask(.promise, with: rq).map { data, _ -> MaplyViewControllerLayer in
            let json = try JSON(data: data)
            
            let tileSource = MaplyRemoteTileSource(tilespec: json.object as! [String : Any])!
            tileSource.cacheDir = self.cacheDir.absoluteString + "/" + json["id"].string!
            
            let layer = MaplyQuadImageTilesLayer(coordSystem:tileSource.coordSys, tileSource:tileSource)!
            layer.handleEdges = true
            layer.coverPoles = true
            layer.waitLoad = false
            layer.drawPriority = kMaplyImageLayerDrawPriorityDefault
            layer.singleLevelLoading = false
            
            return layer
        }
    }
}
