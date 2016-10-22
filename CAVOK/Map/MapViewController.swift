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
    
    @IBOutlet weak var bottomView: UIView!
    
    @IBOutlet weak var status: UITextField!

    @IBOutlet weak var moduleType: UISegmentedControl!
    
    @IBOutlet weak var timeslots: TimeslotView!
    
    @IBOutlet weak var region: UIButton!
    
    @IBOutlet weak var webView: UIButton!
    
    
    internal var mapView: WhirlyGlobeViewController!

    fileprivate let modules = Modules()
    
    fileprivate var module: MapModule!
    
    fileprivate var components: [NSObject: MaplyComponentObject] = [:]
    
    private var locationManager: LocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        region.layer.borderWidth = 1
        region.layer.borderColor = view.tintColor.cgColor
        region.layer.cornerRadius = 5
        region.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        webView.layer.borderWidth = 1
        webView.layer.borderColor = view.tintColor.cgColor
        webView.layer.cornerRadius = 5
        webView.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        mapView = WhirlyGlobeViewController()
        mapView.delegate = self
        
        view.insertSubview(mapView.view, at: 0)
        mapView.view.frame = view.bounds
        addChildViewController(mapView)
        
        mapView.keepNorthUp = true
        mapView.frameInterval = 2 // 30fps
        mapView.threadPerLayer = true
        mapView.autoMoveToTap = false
        
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
        return self.region.isSelected && WeatherRegion.load() == nil
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
    
    @IBAction func openWebView() {
        
        self.performSegue(withIdentifier: "OpenBrowser", sender: self)
    }
    
    @IBAction func resetRegion() {
        let start = !region.isSelected
        region.isSelected = start
        if start {
            animateModuleType(show: false)
            animateTimeslots(show: false)
        }
        module.configure(open: start, userLocation: nil)
    }
    
    fileprivate func animateModuleType(show: Bool) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.moduleType.alpha = (show ? 1 : 0)
        }, completion: { finished in
            self.moduleType.isHidden = self.moduleType.alpha == 0
        })
    }
    
    fileprivate func animateTimeslots(show: Bool) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            let height: CGFloat = (show ? 80 : 40)
            self.bottomView.frame.origin = CGPoint(x: 0, y: self.view.bounds.height - height)
        })
    }
    
    
    @IBAction func moduleTypeChanged() {
        module = nil
        module = modules.loadModule(index: moduleType.selectedSegmentIndex, delegate: self)
    }
    
    @IBAction func timeslotChanged() {
        module.render(frame: timeslots.selectedSegmentIndex)
    }
    
}

// MARK: - MapDelegate
extension MapViewController : MapDelegate {

    func setStatus(error: Error) {
        switch error {
        case let Weather.error(msg):
            setStatus(text: msg)
        default:
            print(error)
            setStatus(text: error.localizedDescription)
        }
        
    }
    
    func setStatus(text: String?, color: UIColor = UIColor.red) {
        if let text = text {
            DispatchQueue.main.async {
                self.status.textColor = color
                self.status.text = "\(text)"
            }
        }
    }
    
    func loaded(frame:Int?, timeslots: [Timeslot]) {
        DispatchQueue.main.async {
            if let frame = frame {
                self.timeslots.removeAllSegments()
                for (index, slot) in timeslots.enumerated() {
                    self.timeslots.insertSegment(with: slot, at: index, animated: true)
                }
                
                self.animateTimeslots(show: true)
                self.animateModuleType(show: true)
                
                self.timeslots.selectedSegmentIndex = frame
            } else {
                self.animateTimeslots(show: false)
                self.animateModuleType(show: false)
            }
            // make sure region selection is canceled
            self.region.isHidden = false
            self.region.isSelected = false
            self.webView.isHidden = false
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
}

// MARK: - UITextFieldDelegate
extension MapViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == self.status {
            module.refresh()
        }
        return false
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
        
        if self.region.isSelected {
            module.didTapAt(coord: coord)
            return
        }
        
        if let marker = selected as? MaplyScreenMarker {
            if let contentView = module.annotation(object: marker.userObject, parentFrame: self.view.frame) {
                let annotation = MaplyAnnotation()
                annotation.contentView = contentView
                view.addAnnotation(annotation, forPoint: marker.loc, offset: .zero)
            }
        }
    }
}
