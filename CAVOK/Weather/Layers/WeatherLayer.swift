//
//  WeatherLayer.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 08.03.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import SwiftUI

class WeatherLayer {

    private let mapView: WhirlyGlobeViewController

    let presentation: ObservationPresentation

    private var config = WeatherConfig()

    var loader: MaplyQuadImageFrameLoader?

    var fetcher: WeatherTileFetcher?

    private var frameChanger: FrameChanger?

    let DEBUG = false

    init(mapView: WhirlyGlobeViewController, presentation: ObservationPresentation) {
        self.mapView = mapView
        self.presentation = presentation
    }

    deinit {
        clean()
    }

    func load(slots: [Timeslot], selected: Int?, at coordinate: CLLocationCoordinate2D?, loaded: @MainActor @escaping (Int, Color) -> Void) {
        clean()

        guard !slots.isEmpty else {
            return
        }

        // generate heatmaps in inverse order
        let frames = slots.enumerated().map { index, slot in
            HeatMap(index: index, observations: slot.observations, config: config, presentation: self.presentation)
        }

        frames.reversed().forEach { frame in
            let selected = frame.index == selected

            Task(priority: selected ? .userInitiated : .low) {
                frame.process()
                if let coordinate = coordinate {
                    await loaded(frame.index, Color(frame.color(for: coordinate)))
                }
            }
        }

        DispatchQueue.main.async {
            self.loader = self.initLoader(frames: frames)
        }
    }

    func go(frame: Int) -> [Observation] {
        if let frameChanger = self.frameChanger {
            frameChanger.go(frame)
        }

        if let fetcher = fetcher, frame < fetcher.frames.count {
            let tileSource = fetcher.frames[frame]
            return tileSource.observations
        } else {
            return []
        }
    }

    func clean() {
        if let frameChanger = self.frameChanger {
            mapView.remove(frameChanger)
        }
        loader?.shutdown()
        loader = nil
    }

    private func initLoader(frames: [HeatMap]) -> MaplyQuadImageFrameLoader? {
        self.fetcher = DEBUG
            ? DebugTileFetcher(frames: frames, config: config)
            : WeatherTileFetcher(frames: frames, config: config)

        let params = MaplySamplingParams()
        params.coverPoles = false
        params.edgeMatching = false
        params.maxZoom = Int32(config.maxZoom)
        params.coordSys = MaplySphericalMercator(webStandard: ())
        params.singleLevel = true

        let customTilerSources = frames.map { frame in
            WeatherTileInfo(config: config, frame: frame.index)
        }

        guard let loader = MaplyQuadImageFrameLoader(params: params,
                                                     tileInfos: customTilerSources,
                                                     viewC: mapView) else {
            print("ERR: Failed to load weather layer")
            return nil
        }
        
        loader.setCurrentImage(Double(frames.count - 2))

        loader.setTileFetcher(fetcher!)
        loader.baseDrawPriority = kMaplyImageLayerDrawPriorityDefault + 1000
        loader.setTileFetcher(self.fetcher!)

        if let debugTileFetcher = fetcher as? DebugTileFetcher {
            debugTileFetcher.loader = loader
        }

        let frameChanger = FrameChanger(loader: loader)
        mapView.add(frameChanger)
        self.frameChanger = frameChanger

        return loader
    }
}
