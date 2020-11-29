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
    
    var loader: MaplyQuadImageLoader? = nil
    
    var fetcher: WeatherTileFetcher? = nil
    
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
//            self.setupLoader(self.mapView)
        }
    }
    
    func go(frame: Int) -> [Observation] {
        if let frameChanger = self.frameChanger {
            frameChanger.go(frame)
        }
        
        if let tileSource = fetcher {
            return tileSource.frames[frame].observations
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
        
        fetcher?.shutdown()
        fetcher = nil

    }
    
    private func initLoader(frames: [HeatMap]) -> MaplyQuadImageLoader? {
//        // for debugging tiles
//        guard let fetcher = DebugTileFetcher(frames: frames, config: config!) else {
        
        guard let fetcher = WeatherTileFetcher(frames: frames, config: config!) else {
            return nil
        }
        self.fetcher = fetcher
        
        let params = MaplySamplingParams()
        params.coverPoles = true
        params.edgeMatching = true
        params.minZoom = fetcher.minZoom()
        params.maxZoom = fetcher.maxZoom()
        params.coordSys = MaplySphericalMercator(webStandard: ())
        params.singleLevel = true
        
//        let layer = MaplyQuadImageTilesLayer(coordSystem:tileSource.coordSys(), tileSource:tileSource)!
//        layer.waitLoad = false
//        layer.flipY = false
//        layer.drawPriority = kMaplyImageLayerDrawPriorityDefault + 10
//        layer.singleLevelLoading = false
//        layer.imageDepth = UInt32(frames.count)
//        layer.currentImage = Float(frames.count - 1)
//        layer.allowFrameLoading = true
//
        //        mapView.add(layer)
        
//        guard let loader = MaplyQuadImageFrameLoader(params: params, tileInfos: [fetcher.tileInfo()!], viewC: mapView) else {
        guard let loader = MaplyQuadImageLoader(params: params, tileInfo: fetcher.tileInfo(), viewC: mapView) else {
            print("ERR: Failed to load weather layer")
            return nil
        }
        loader.setTileFetcher(fetcher)
        loader.baseDrawPriority = kMaplyImageLayerDrawPriorityDefault + 10
        
        fetcher.loader = loader
        
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
    
    let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
    var imageLayer : MaplyQuadImageFrameLoader? = nil
    var imageAnimator : MaplyQuadImageFrameAnimator? = nil
    var varTarget : MaplyVariableTarget? = nil
    
    var rampTex : MaplyTexture? = nil
    
    var timer : Timer? = nil
    
    var tileSources : [MaplyRemoteTileInfoNew] = []
    
    // Put together a sampling layer and loader
    func setupLoader(_ baseVC: MaplyBaseViewController) {
        

        for i in 0...4 {
            let precipSource = MaplyRemoteTileInfoNew(baseURL: "http://a.tiles.mapbox.com/v3/mousebird.precip-example-layer\(i)/{z}/{x}/{y}.png",
                minZoom: 0,
                maxZoom: 6)
            precipSource.cacheDir = "\(cacheDir)/forecast_io_weather_layer\(i)/"
            tileSources.append(precipSource)
        }
        
        // Set up a variable target for two pass rendering
        varTarget = MaplyVariableTarget(type: .imageIntRGBA, viewC: baseVC)
        varTarget?.setScale(0.5)
        varTarget?.clearEveryFrame = true
        varTarget?.drawPriority = kMaplyImageLayerDrawPriorityDefault + 1000
        
        // Parameters describing how we want a globe broken down
        let sampleParams = MaplySamplingParams()
        sampleParams.coordSys = MaplySphericalMercator(webStandard: ())
        sampleParams.coverPoles = false
        sampleParams.edgeMatching = false
        sampleParams.minZoom = 0
        sampleParams.maxZoom = 6
        sampleParams.singleLevel = true
        sampleParams.minImportance = 1024.0*1024.0

        imageLayer = MaplyQuadImageFrameLoader(params: sampleParams, tileInfos: tileSources, viewC: baseVC)
//        imageLayer?.debugMode = true;
        if let varTarget = varTarget {
            imageLayer?.setRenderTarget(varTarget.renderTarget)
        }

        guard let shader = baseVC.getShaderByName(kMaplyShaderDefaultTriMultiTexRamp) else {
            return
        }
        imageLayer?.setShader(shader)
        
        // Assign the ramp texture to the first entry in the texture lookup slot
        guard let rampTex = baseVC.addTexture(UIImage.init(named: "colorramp.png")!, desc: nil, mode: .current) else {
            return
        }
        shader.setTexture(rampTex, for: 0, viewC: baseVC)
        
        // Animator
        imageAnimator = MaplyQuadImageFrameAnimator(frameLoader: imageLayer!, viewC: baseVC)
        imageAnimator?.period = 15.0
        imageAnimator?.pauseLength = 3.0
        
        // Periodic stats
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true)
        {
            timer in
            let stats = self.imageLayer!.getFrameStats()
            print("Loading stats")
            var which = 0
            for frame in stats.frames {
                print("frame \(which):  \(frame.tilesToLoad) to load of \(frame.totalTiles))")
                which += 1
            }
        }
        
        // Color changing test
//        imageLayer?.color = UIColor.green
//        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
//            self.imageLayer?.color = UIColor.blue
//        }
    }
}
