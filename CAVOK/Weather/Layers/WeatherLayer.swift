//
//  WeatherLayer.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 08.03.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class WeatherLayer {

    private let mapView: WhirlyGlobeViewController
    private let observationValue: (Observation) -> Int?
    private let ramp: ColorRamp
    
    private var config: WeatherConfig?
    
    private var layer: MaplyQuadImageTilesLayer? = nil
    
    private var frameChanger: FrameChanger? = nil
    
    init(mapView: WhirlyGlobeViewController, ramp: ColorRamp, observationValue: @escaping (Observation) -> Int?, region: WeatherRegion?) {
        self.mapView = mapView
        self.observationValue = observationValue
        self.ramp = ramp
        
        if let region = region {
            reposition(region: region)
        }
    }
    
    deinit {
        clean()
    }
    
    func reposition(region: WeatherRegion) {
        config = WeatherConfig(region: region)
    }
    
    func load(groups: ObservationGroups) {
        guard let _ = config, let selected = groups.selectedFrame else {
            return
        }
        
        clean()
        
        let layer = initLayer(groups: groups)
        mapView.add(layer)
        self.layer = layer
        
        // load selected frame first and then others in reverse order
        var priorities: [Int] = Array(0...groups.count - 1)
        priorities.remove(at: selected)
        priorities.append(selected)
        layer.setFrameLoadingPriority(priorities.reversed())
        
        let frameChanger = FrameChanger(layer: layer)
        mapView.add(frameChanger)
        self.frameChanger = frameChanger
    }
    
    func go(frame: Int) -> [Observation] {
        if let frameChanger = self.frameChanger {
            frameChanger.go(frame)
        }
        
        if let tileSource = layer?.tileSource as? WeatherTileSource {
            return tileSource.frames[frame].observations
        } else {
            return []
        }
    }
    
    func clean() {
        if let frameChanger = self.frameChanger {
            mapView.remove(frameChanger)
        }
        if let layer = self.layer {
            mapView.remove(layer)
        }
    }
    
    private func initLayer(groups: ObservationGroups) -> MaplyQuadImageTilesLayer {
        
        // generate heatmaps in inverse order
        let frames = groups.frames.enumerated().map { (frame, obs) in
            return HeatMap(observations: obs, config: config!, observationValue: observationValue, ramp: ramp, frame: frame, priority: frame == groups.selectedFrame)
        }
        
        // for debugging tiles
        //let tileSource = DebugTileSource(frames: frames, config: config)
        
        let tileSource = WeatherTileSource(frames: frames, config: config!)
        
        let layer = MaplyQuadImageTilesLayer(coordSystem:tileSource.coordSys(), tileSource:tileSource)!
        layer.handleEdges = false
        layer.coverPoles = false
        layer.waitLoad = false
        layer.flipY = false
        layer.drawPriority = kMaplyImageLayerDrawPriorityDefault + 10
        layer.singleLevelLoading = false
        layer.imageDepth = UInt32(frames.count)
        layer.currentImage = Float(frames.count - 1)
        layer.allowFrameLoading = true
        
        return layer
    }
}
