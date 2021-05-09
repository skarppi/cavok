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

    var loader: MaplyQuadImageFrameLoader?

    var fetcher: WeatherTileFetcher?

    private var frameChanger: FrameChanger?

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
        guard let selected = groups.selectedFrame else {
            return
        }

        clean()

        // generate heatmaps in inverse order
        let frames = groups.frames.enumerated().map { index, obs in
            return HeatMap(index: index, observations: obs, config: config!, presentation: self.presentation)
        }

        frames.reversed().forEach { frame in
            let selected = frame.index == selected
            frame.process(priority: selected).done {
                if let coordinate = coordinate {
                    loaded(frame.index, frame.color(for: coordinate))
                }
            }.catch { error in
                print("Failed to generate heatmap \(frame.index) because of \(error)")
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
            // when reloading data the observations might get deleted
            return tileSource.observations.filter({!$0.isInvalidated})
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

        //        fetcher?.shutdown()
        //        fetcher = nil

    }

    private func initLoader(frames: [HeatMap]) -> MaplyQuadImageFrameLoader? {
        //        // for debugging tiles

        self.fetcher = // frames.compactMap { frame in
            //            DebugTileFetcher(frames: frames, config: config!)
            WeatherTileFetcher(frames: frames, config: config!)
        //        }

        let params = MaplySamplingParams()
        params.coverPoles = false
        params.edgeMatching = false
        params.maxZoom = Int32(config!.maxZoom)
        params.coordSys = MaplySphericalMercator(webStandard: ())
        params.singleLevel = true

        //        let layer = MaplyQuadImageTilesLayer(coordSystem:tileSource.coordSys(), tileSource:tileSource)!
        //        layer.imageDepth = UInt32(frames.count)
        //        layer.currentImage = Float(frames.count - 1)
        //        layer.allowFrameLoading = true
        //

        let customTilerSources = frames.map { frame in
            WeatherTileInfo(config: config!, frame: frame.index)
        }

        //        let customTileSources2 = frames.map { frame in
        //            fetcher.
        //        }

        // Set up a variable target for two pass rendering
        //        varTarget = MaplyVariableTarget(type: .imageIntRGBA, viewC: mapView)
        //        varTarget?.setScale(0.5)
        //        varTarget?.clearEveryFrame = true
        //        varTarget?.drawPriority = kMaplyImageLayerDrawPriorityDefault + 1000

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

        //
        //        if let varTarget = varTarget {
        //            loader.setRenderTarget(varTarget.renderTarget)
        //        }
        //
        //        guard let shader = mapView.getShaderByName(kMaplyShaderDefaultTriMultiTexRamp) else {
        //            return nil
        //        }
        //        loader.setShader(shader)
        //
        //        // Assign the ramp texture to the first entry in the texture lookup slot
        //        guard let rampTex = mapView.addTexture(UIImage.init(named: "colorramp.png")!,
        //                                               desc: nil, mode: .current) else {
        //            return nil
        //        }
        //        shader.setTexture(rampTex, for: 0)
        //
        if let debugTileFetcher = fetcher as? DebugTileFetcher {
            debugTileFetcher.loader = loader
        }

        // load selected frame first and then others in reverse order
        //        var priorities: [Int] = Array(0...groups.count - 1)
        //        priorities.remove(at: selected)
        //        priorities.append(selected)
        //        loader.setFrameLoadingPriority(priorities.reversed())

        let frameChanger = FrameChanger(loader: loader)
        mapView.add(frameChanger)
        self.frameChanger = frameChanger

        return loader
    }
}
