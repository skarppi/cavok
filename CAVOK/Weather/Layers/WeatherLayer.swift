//
//  WeatherLayer.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 08.03.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class WeatherLayer {

    private let delegate: MapDelegate
    private let observationValue: (Observation) -> Int?
    private let ramp: ColorRamp
    
    private var config: WeatherConfig?
    
    private var layer: MaplyQuadImageTilesLayer? = nil
    
    private var frameChanger: FrameChanger? = nil
    
    init(module: MapModule, delegate: MapDelegate, observationValue: @escaping (Observation) -> Int?) {
        self.delegate = delegate
        self.observationValue = observationValue
        self.ramp = ColorRamp(module: module)
    }
    
    deinit {
        clean()
    }
    
    func reposition() {
        if let region = WeatherRegion.load() {
            config = WeatherConfig(region: region)
        }
    }
    
    func render(observations: [Observation]) {
        if config == nil {
            reposition()
        }
        
        clean()
        
        let grouped = group(observations: observations)
        
        let layer = initLayer(grouped: grouped.map { $0.1 })
        delegate.mapView.add(layer)
        self.layer = layer
        
        let priorities: [Int] = Array(0...grouped.count-1).reversed()
        layer.setFrameLoadingPriority(priorities)
        
        let frameChanger = FrameChanger(layer: layer)
        delegate.mapView.add(frameChanger)
        self.frameChanger = frameChanger
        
        delegate.setTimeslots(slots: grouped.map { $0.0})
    }
    
    func go(index: Int) {
        if let frameChanger = self.frameChanger {
            frameChanger.go(index)
        }
    }
    
    private func clean() {
        if let frameChanger = self.frameChanger {
            delegate.mapView.remove(frameChanger)
        }
        if let layer = self.layer {
            delegate.mapView.remove(layer)
        }
    }
    
    private func initLayer(grouped: [[Observation]]) -> MaplyQuadImageTilesLayer {
        
        let frames = grouped.enumerated().map { (index, obs) in
            return HeatMap(observations: obs, config: config!, observationValue: observationValue, ramp: ramp, frame: index)
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
        //layer.animationWrap = true
        //layer.animationPeriod = 1.0
        
        return layer
    }
    
    private func group(observations: [Observation]) -> [(Date, [Observation])] {
        let uniqueTimes = Array(Set(observations.map { $0.datetime })).sorted { $0 < $1 }
        
        let cal = Calendar.current
        
        let slots: [Date]
        if uniqueTimes.count <= 6 {
            slots = uniqueTimes
        } else {
            let last = uniqueTimes.last!
            
            let filtered = uniqueTimes.filter { date in
                return last.timeIntervalSince(date) / 3600 < 6
            }
            
            let first = filtered.first!
            let historyLength = Int(ceil(last.timeIntervalSince(first) / 1800))
            
            let offset: Int = {
                let minutes = cal.component(.minute, from: first)
                if minutes == 50 || minutes == 20 {
                    return 0
                } else if minutes > 50 {
                    return minutes - 60
                } else if minutes > 20 {
                    return minutes - 50
                } else {
                    return minutes - 20
                }
            }()
            
            slots = [Int](repeating: 0, count: historyLength).enumerated().map { (index: Int, element: Int) -> Date in
                return cal.date(byAdding: .minute, value: index * 30 - offset, to: first)!
            }
        }
        
        return slots.enumerated().flatMap { (index: Int, slot: Date) -> (Date, [Observation])? in
            let nextSlot: Date?
            if (index + 1) < slots.count {
                nextSlot = slots[index+1]
            } else {
                nextSlot = nil
            }
            
            let group = observations.filter { (obs) -> Bool in
                return obs.datetime >= slot && nextSlot.map { obs.datetime < $0 } ?? true
            }
            if group.isEmpty {
                return nil
            } else {
                return (slot, group)
            }
        }
    }
}
