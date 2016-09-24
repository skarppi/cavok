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
    
    init(mapView: WhirlyGlobeViewController, ramp: ColorRamp, observationValue: @escaping (Observation) -> Int?) {
        self.mapView = mapView
        self.observationValue = observationValue
        self.ramp = ramp
    }
    
    deinit {
        clean()
    }
    
    func reposition() {
        if let region = WeatherRegion.load() {
            config = WeatherConfig(region: region)
        }
    }
    
    func render(groups: [[Observation]]) -> Int? {
        if groups.isEmpty {
            return nil
        }
        
        if config == nil {
            reposition()
        }
        
        clean()
        
        let layer = initLayer(groups: groups)
        mapView.add(layer)
        self.layer = layer
        
        // load last frames first
        let priorities: [Int] = Array(0...groups.count - 1).reversed()
        layer.setFrameLoadingPriority(priorities)
        
        let frameChanger = FrameChanger(layer: layer)
        mapView.add(frameChanger)
        self.frameChanger = frameChanger
        
        return groups.count - 1
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
    
    private func clean() {
        if let frameChanger = self.frameChanger {
            mapView.remove(frameChanger)
        }
        if let layer = self.layer {
            mapView.remove(layer)
        }
    }
    
    private func initLayer(groups: [[Observation]]) -> MaplyQuadImageTilesLayer {
        
        let frames = groups.enumerated().map { (frame, obs) in
            return HeatMap(observations: obs, config: config!, observationValue: observationValue, ramp: ramp, frame: frame)
        }
        
        // for debugging tiles
        //let tileSource = DebugTileSource(frames: frames, config: config)
        
        let tileSource = WeatherTileSource(frames: frames, config: config!)
        tileSource.preload(frames.count - 1)
        
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
