//
//  WeatherModule.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 08.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

final class WeatherModule: MapModule {

    private let delegate: MapDelegate
    
    let weatherServer = WeatherServer()
    
    init(delegate: MapDelegate) {
        self.delegate = delegate
    }
    
    func didTapAt(coord: MaplyCoordinate) {
        if let selection = delegate.findComponent(ofType: RegionSelection.self) as? RegionSelection {
            selection.region.center = coord
            startRegionSelection(region: selection.region)
        }
    }
    
    private func startRegionSelection(region: WeatherRegion) {
        self.delegate.clearComponents(ofType: RegionSelection.self)
        self.delegate.clearAnnotations(ofType: RegionAnnotationView.self)

        let annotation = RegionAnnotationView(region: region, closed: { region in
            self.delegate.clearComponents(ofType: RegionSelection.self)
            self.delegate.clearAnnotations(ofType: RegionAnnotationView.self)
            if region.save() {
                self.refreshStations()
            }
        }, resized: { region in
            self.startRegionSelection(region: region)
        })
        
        let selection = RegionSelection(region: region)
        
        if let stickers = self.delegate.mapView.addStickers([selection], desc: [kMaplyFade: 1.0]) {
            self.delegate.addComponents(key: selection, value: stickers)
        }
        self.delegate.mapView.addAnnotation(annotation, forPoint: region.center, offset: CGPoint.zero)
    }
    
    func resetRegion(centerPoint: MaplyCoordinate?) {
        if let region = WeatherRegion.load() {
            startRegionSelection(region: region)
        } else {
            let center = centerPoint ?? delegate.mapView.getPosition()
            startRegionSelection(region: WeatherRegion(center: center, radius: 100))
        }
    }
    
    func refresh() {
        weatherServer.refreshObservations().then(execute: { stations -> Void in
            self.delegate.setStatus(text: "\(stations.count)", color: UIColor.red)
        }).catch(execute: { error -> Void in
            self.delegate.setStatus(error: error)
        })
    }
    
    fileprivate func refreshStations() {
        delegate.setStatus(text: "Reloading stations...", color: UIColor.black)
        
        weatherServer.refreshStations().then { stations -> Void in
            self.refresh()
        }.catch { error -> Void in
            self.delegate.setStatus(error: error)
        }
    }
    
}
