//
//  MapViewController.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 04.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import UIKit
import CoreLocation
import PromiseKit

class MapViewController: UIViewController {
    
    @IBOutlet internal var mapView: WhirlyGlobeViewController!

    private var components: [NSObject: MaplyComponentObject] = [:]
    
    private var locationManager: LocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create an empty globe and add it to the view
        mapView = WhirlyGlobeViewController()
        
        self.view.addSubview(mapView.view)
        mapView.view.frame = self.view.bounds
        addChildViewController(mapView)
        
        mapView.keepNorthUp = true
        mapView.frameInterval = 2 // 30fps
        mapView.threadPerLayer = true
        mapView.autoMoveToTap = false
        
        if let (center, height) = LastSession.load() {
            mapView.height = height
            mapView.setPosition(center)
        }
        
        if let basemap = UserDefaults.standard.string(forKey: "basemapURL"), let url = URL(string: basemap) {
            TileJSONLayer().load(url: url).then { layer in
                self.mapView.add(layer)
            }.catch { e in
                print(e)
            }
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MapViewController.enteredBackground(notification:)),
                                               name: .UIApplicationDidEnterBackground,
                                               object: nil
        )
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MapViewController.enteredForeground(notification:)),
                                               name: .UIApplicationWillEnterForeground,
                                               object: nil
        )
        
        locationManager = LocationManager(
            fulfill: userLocationChanged,
            reject: { error in
                self.clearComponents(of: UserMarker.self)
            })
        locationManager.requestLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func enteredBackground(notification: Notification) {
        LastSession.save(center: mapView.getPosition(), height: mapView.getHeight())
    }
    
    func enteredForeground(notification: Notification) {
        locationManager.requestLocation()
    }

    func userLocationChanged(coordinate: MaplyCoordinate) {
        clearComponents(of: UserMarker.self)
        
        let userLocation = UserMarker(coordinate: coordinate)
        if let objects = mapView.addScreenMarkers([userLocation], desc: nil) {
            components[userLocation] = objects
        }
        
        let bbox = mapView.getCurrentExtents()
        let height = LastSession.load()?.height
        if height == nil || !bbox.inside(coordinate) {
            mapView.height = height ?? 0.2
            mapView.animate(toPosition: coordinate, time:0.5)
        }
    }
    
    func clearComponents(of: NSObject.Type?) {
        if let filter = of {
            let matching = components.filter { (key,_) in
                type(of: key) == filter
            }
            let objects = matching.flatMap { (key, _) in
                components.removeValue(forKey: key)
            }
            mapView.remove(objects)
        } else {
            mapView.remove([MaplyComponentObject](components.values))
            components.removeAll()
        }
    }
}
