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
    
    private let presentation: ObservationPresentation
    
    private var config: WeatherConfig?
    
    private var layer: MaplyQuadImageTilesLayer? = nil
    
    private var frameChanger: FrameChanger? = nil
    
    init(mapView: WhirlyGlobeViewController, presentation: ObservationPresentation, region: WeatherRegion?) {
        self.mapView = mapView
        self.presentation = presentation
        
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
    
    func load(groups: ObservationGroups, at coordinate: MaplyCoordinate?, loaded: @escaping (Int, UIColor) -> Void) {
        guard let config = config, let selected = groups.selectedFrame else {
            return
        }
        
        clean()
        
        // generate heatmaps in inverse order
        let frames = groups.frames.enumerated().map { index, obs in
            return HeatMap(index: index, observations: obs, config: config, presentation: self.presentation)
        }
        
        frames.reversed().forEach { frame in
            let selected = frame.index == selected
            frame.process(priority: selected).then { Void -> Void in
                if let coordinate = coordinate {
                    loaded((frame.index, frame.color(for: coordinate)))
                }
            }.catch(execute: { error in
                print("Failed to generate heatmap \(frame.index) because of \(error)")
            })
        }
        
        let layer = initLayer(frames: frames)
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
    
    private func initLayer(frames: [HeatMap]) -> MaplyQuadImageTilesLayer {
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
