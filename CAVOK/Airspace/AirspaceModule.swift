//
//  AirspaceModule.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 25.02.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import SwiftyJSON
import PMKFoundation
import PromiseKit

class tma: NSObject {
}

class ctr: NSObject {
}

class prohibitedAreas: NSObject {
}

final class AirspaceModule: MapModule {
    
    let delegate: MapDelegate
    
    let frames = [tma.self, ctr.self, prohibitedAreas.self] as [NSObject.Type]
    
    init(delegate: MapDelegate) {
        self.delegate = delegate
        
        if let airspaces = UserDefaults.standard.stringArray(forKey: "airspaces") {
            airspaces.forEach { airspace in
                self.render(frame: frames.firstIndex(where: { String(describing: $0) == airspace})!)
            }
        }
    }
    
    func didTapAt(coord: MaplyCoordinate) {
        delegate.mapView.clearAnnotations()
    }
    
    func refresh() -> Promise<Void> {
        return .value(())
    }
    
    func configure(open: Bool) {
    }
    
    func render(frame: Int) {
        let key = frames[frame]
        let current = String(describing: key)
        let url = UserDefaults.standard.string(forKey: "airspaceURL")! + "/" + current
        
        var airspaces = UserDefaults.standard.stringArray(forKey: "airspaces") ?? []
        if let index = airspaces.firstIndex(of: current) {
            self.delegate.clearComponents(ofType: key)
            airspaces.remove(at: index)
        } else {
            airspaces.append(current)
            
            NSLog("Fetching airspace data from \(url)")
            let rq = URLRequest(url: URL(string: url)!)
            URLSession.shared.dataTask(.promise, with: rq).done { data, _ in
                self.showVectors(key: key, data: data)
            }.catch(Messages.show)
        }
        UserDefaults.standard.setValue(airspaces, forKey: "airspaces")
    }
    
    func details(object: Any, parentFrame: CGRect) {
        guard let vector = object as? MaplyVectorObject,
              let attributes = vector.attributes as? [String: String] else {
            return
        }
        let annotation = MaplyAnnotation()
        annotation.contentView = AirspaceCalloutView(name: attributes["name"]!, description: attributes["description"]!, parentFrame: parentFrame)
        delegate.mapView.addAnnotation(annotation, forPoint: vector.centroid(), offset: .zero)
    }
    
    private func showVectors(key: NSObject.Type, data: Data) {
        if let vector = MaplyVectorObject(fromGeoJSON: data) {
            
            let attrs = try! JSON(data: data)
            
            let isoFormatter = DateFormatter()
            isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            if let validFrom = isoFormatter.date(from: attrs["validFrom"].stringValue) {
                let validUntil = attrs["validUntil"].string.flatMap { str in
                    return isoFormatter.date(from: str)
                }.map { date in
                    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)!
                    return " until \(dateFormatter.string(from: yesterday))"
                } ?? ""
                Messages.show(text: "From \(dateFormatter.string(from: validFrom))" + validUntil)
            }
            
            vector.splitVectors().forEach {
                let vector = $0 
                let attributes = AirspaceAttributes(attributes: vector.attributes as! [String: AnyObject])
                vector.attributes?.setValue(attributes.name, forKey: "name")
                vector.attributes?.setValue(attributes.description, forKey: "description")
                vector.attributes?.setValue(attributes.lowerLimit ?? 0, forKey: kMaplyDrawPriority)
                
                if let objects = self.delegate.mapView.addVectors([vector], desc: [
                    kMaplyColor: attributes.color,
                    kMaplySelectable: true,
                    kMaplyVecWidth: 2.0,
                    kMaplyFade: 1.0
                    ]) {
                    self.delegate.addComponents(key: key.init(), value: objects)
                }
            }
        }
    }
    
    func cleanup() -> Void {
        delegate.clearComponents(ofType: tma.self)
        delegate.clearComponents(ofType: ctr.self)
        
        delegate.mapView.clearAnnotations()
    }
}
