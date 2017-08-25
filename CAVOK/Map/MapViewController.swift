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
import Pulley

class MapViewController: UIViewController {
    
    @IBOutlet weak var moduleType: UISegmentedControl!
    
    @IBOutlet weak var buttonView: UIView!
    
    @IBOutlet weak var legendView: LegendView!
    
    internal var mapView: WhirlyGlobeViewController!
    
    fileprivate var module: MapModule!
    
    fileprivate var airspaceModule: AirspaceModule!
    
    fileprivate var components: [NSObject: MaplyComponentObject] = [:]
    
    private var locationManager: LocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMapView()
        
        Messages.setup()
        
        setupObservers()
        
        setupLocationManager()

        setupModules()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        moduleTypeChanged()
    }
    
    func setupMapView() {
        mapView = WhirlyGlobeViewController()
        mapView.delegate = self
        
        view.insertSubview(mapView.view, at: 0)
        mapView.view.frame = view.bounds
        addChildViewController(mapView)
        
        mapView.keepNorthUp = true
        mapView.frameInterval = 2 // 30fps
        mapView.threadPerLayer = true
        mapView.autoMoveToTap = false
        mapView.clearColor = view.backgroundColor
        
        if let (center, height) = LastSession.load() {
            mapView.height = height
            mapView.setPosition(center)
        } else {
            mapView.height = 0.7
            mapView.setPosition(MaplyCoordinateMakeWithDegrees(10, 50))
        }
        
        if let basemap = UserDefaults.standard.string(forKey: "basemapURL"), let url = URL(string: basemap) {
            TileJSONLayer().load(url: url).then { layer in
                self.mapView.add(layer)
            }.catch { error in
                Messages.show(error: error)
            }
        }
    }
    
    func setupLocationManager() {
        locationManager = LocationManager(
            fulfill: userLocationChanged,
            reject: { error in
                self.clearComponents(ofType: UserMarker.self)
                
                _ = self.ensureConfigured()
        })
        locationManager.requestLocation()
    }
    
    func setupModules() {
        airspaceModule = AirspaceModule(delegate: self)
        
        moduleType.removeAllSegments()
        for (index, title) in Modules.availableTitles().enumerated() {
            moduleType.insertSegment(withTitle: title, at: index, animated: false)
        }
        moduleType.selectedSegmentIndex = 0
    }
    
    func setupObservers() {
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
    }
    
    func enteredBackground(notification: Notification) {
        LastSession.save(center: mapView.getPosition(), height: mapView.getHeight())
    }
    
    func enteredForeground(notification: Notification) {
        locationManager.requestLocation()
    }

    fileprivate func ensureConfigured() -> Bool {
        if WeatherRegion.load() == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.module.configure(open: true)
            })
            return false
        }
        return true
    }
    
    func userLocationChanged(coordinate: MaplyCoordinate) {
        clearComponents(ofType: UserMarker.self)
        
        let userLocation = UserMarker(coordinate: coordinate)
        if let objects = mapView.addScreenMarkers([userLocation], desc: nil) {
            addComponents(key: userLocation, value: objects)
        }
        
        if ensureConfigured() {
            let userMovedOutsideView = LastLocation.load().map { last -> Bool in
                let extents = mapView.getCurrentExtents()
                return extents.inside(last) && !extents.inside(coordinate)
            }
            if userMovedOutsideView ?? true {
                mapView.animate(toPosition: coordinate, time: 0.5)
            }
        }
    }
    
    @IBAction func airspaceLayers() {
        airspaceModule.render(frame: 0)
    }
    
    @IBAction func resetRegion() {
        buttonView.isHidden = true
        legendView.isHidden = true
        
        animateModuleType(show: false)
        module.configure(open: true)
    }
    
    fileprivate func animateModuleType(show: Bool) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.moduleType.alpha = (show ? 1 : 0)
        }, completion: { finished in
            self.moduleType.isHidden = self.moduleType.alpha == 0
        })
    }
    
    @IBAction func moduleTypeChanged() {
        let selectedIndex = moduleType.selectedSegmentIndex
        
        if selectedIndex == moduleType.numberOfSegments - 1 {
            if let module = module, let previousIndex = Modules.index(of: type(of: module)) {
                moduleType.selectedSegmentIndex = previousIndex
            }
        }
        module?.cleanup()
        module = Modules.loadModule(index: selectedIndex, delegate: self)
    }
}

// MARK: - MapDelegate
extension MapViewController : MapDelegate {
    
    func loaded(frame:Int?, legend: Legend) {
        DispatchQueue.main.async {
            self.buttonView.isHidden = false
            
            if frame != nil {
                self.legendView.loaded(legend: legend)
                self.animateModuleType(show: true)
            } else {
                Messages.show(error: "No data")
                self.resetRegion()
            }
        }
    }
    
    func clearAnnotations(ofType: MaplyAnnotation.Type?) {
        if let ofType = ofType, let annotations = mapView.annotations() {
            annotations.forEach { annotation in
                if type(of: annotation) == ofType {
                    mapView.removeAnnotation(annotation as! MaplyAnnotation)
                }
            }
        } else {
            mapView.clearAnnotations()
        }
    }

    func findComponent(ofType: NSObject.Type) -> NSObject? {
        return components.keys.filter { $0.isKind(of: ofType) }.first
    }
    
    func addComponents(key: NSObject, value: MaplyComponentObject) {
        components[key] = value
    }
    
    func clearComponents(ofType: NSObject.Type?) {
        if let ofType = ofType {
            let matching = components
                .filter { type(of: $0.key) == ofType }
                .flatMap { components.removeValue(forKey: $0.key) }
            mapView.remove(matching)
        } else {
            mapView.remove([MaplyComponentObject](components.values))
            components.removeAll()
        }
    }
    
    var pulley: PulleyViewController! {
        get {
            return self.parent as! PulleyViewController
        }
    }
}

// MARK: - WhirlyGlobeViewControllerDelegate
extension MapViewController: WhirlyGlobeViewControllerDelegate {
    func globeViewController(_ view: WhirlyGlobeViewController, didTapAt coord: MaplyCoordinate) {
        view.clearAnnotations()
        
        module.didTapAt(coord: coord)
    }
    
    func globeViewController(_ view: WhirlyGlobeViewController, didSelect selected: NSObject, atLoc coord: MaplyCoordinate, onScreen screenPt: CGPoint) {
        
        view.clearAnnotations()
        
        if self.buttonView.isHidden {
            module.didTapAt(coord: coord)
            return
        }
        
        let location: MaplyCoordinate?
        let contentView: UIView?
        if let marker = selected as? MaplyScreenMarker, let object = marker.userObject {
            contentView = module.annotation(object: object, parentFrame: self.view.frame)
            location = marker.loc
        } else if let object = (selected as? MaplyVectorObject)?.userObject {
            contentView = airspaceModule.annotation(object: object, parentFrame: self.view.frame)
            location = coord
        } else {
            return
        }
        
        if let contentView = contentView, let location = location {
            let annotation = MaplyAnnotation()
            annotation.contentView = contentView
            view.addAnnotation(annotation, forPoint: location, offset: .zero)
        }
    }
}
