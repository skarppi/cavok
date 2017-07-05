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
    
    @IBOutlet weak var legendView: UIView!
    
    @IBOutlet weak var legendText: UITextView!
    
    @IBOutlet weak var legendGradient: LegendGradientView!
    
    internal var mapView: WhirlyGlobeViewController!

    fileprivate let modules = Modules()
    
    fileprivate var module: MapModule!
    
    fileprivate var airspaceModule: AirspaceModule!
    
    fileprivate var components: [NSObject: MaplyComponentObject] = [:]
    
    private var locationManager: LocationManager!
    
    fileprivate var drawer: DrawerViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                self.setStatus(error: error)
            }
        }
        
        airspaceModule = AirspaceModule(delegate: self)
        
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
                self.clearComponents(ofType: UserMarker.self)
                
                if self.isFirstLoad() {
                    self.module.configure(open: true, userLocation: nil)
                }
            })
        locationManager.requestLocation()
        
        moduleType.removeAllSegments()
        for (index, title) in modules.availableTitles().enumerated() {
            moduleType.insertSegment(withTitle: title, at: index, animated: false)
        }
        moduleType.selectedSegmentIndex = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        drawer = pulley.drawerContentViewController as! DrawerViewController
        
        moduleTypeChanged()
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

    fileprivate func isFirstLoad() -> Bool {
        return self.buttonView.isHidden && WeatherRegion.load() == nil
    }
    
    func userLocationChanged(coordinate: MaplyCoordinate) {
        clearComponents(ofType: UserMarker.self)
        
        let userLocation = UserMarker(coordinate: coordinate)
        if let objects = mapView.addScreenMarkers([userLocation], desc: nil) {
            addComponents(key: userLocation, value: objects)
        }
        
        let height = LastSession.load()?.height
        if height == nil || !mapView.getCurrentExtents().inside(coordinate) {
            mapView.animate(toPosition: coordinate, height: height ?? 0.2, heading: 0, time: 0.5)
        }
        
        if isFirstLoad() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { 
                self.module.configure(open: true, userLocation: userLocation.loc)
            })
        }
    }
    
    @IBAction func airspaceLayers() {
        airspaceModule.render(frame: 0)
    }
    
    @IBAction func openWebView() {
        
        self.performSegue(withIdentifier: "OpenBrowser", sender: self)
    }
    
    @IBAction func resetRegion() {
        buttonView.isHidden = true
        animateModuleType(show: false)
        module.configure(open: true, userLocation: nil)
    }
    
    fileprivate func animateModuleType(show: Bool) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.moduleType.alpha = (show ? 1 : 0)
        }, completion: { finished in
            self.moduleType.isHidden = self.moduleType.alpha == 0
        })
    }
    
    @IBAction func moduleTypeChanged() {
        module = nil
        module = modules.loadModule(index: moduleType.selectedSegmentIndex, delegate: self)
        drawer?.setModule(module: module)
    }
}

// MARK: - MapDelegate
extension MapViewController : MapDelegate {

    func setStatus(error: Error) {
        DispatchQueue.main.async {
            self.drawer.setStatus(error: error)
        }
    }
    
    func setStatus(text: String?, color: UIColor = UIColor.red) {
        DispatchQueue.main.async {
            self.drawer.setStatus(text: text, color: color)
        }
    }
    
    func loaded(frame:Int?, timeslots: [Timeslot], legend: Legend) {
        DispatchQueue.main.async {
            self.pulley.setDrawerContentViewController(controller: self.drawer)
            self.drawer.loaded(frame: frame, timeslots: timeslots, legend: legend)
            self.pulley.setDrawerPosition(position: .collapsed)
            
            self.animateModuleType(show: frame != nil)

            self.buttonView.isHidden = false
            
            self.legendText.text = legend.unit + "\n" + legend.titles.joined(separator: "\n")
            self.legendGradient.gradient(ramp: legend.gradient)
            self.legendView.isHidden = false
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
