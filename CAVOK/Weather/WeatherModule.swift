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
    
    func refreshData() {
        weatherServer.refreshStations().then(execute: { stations -> Void in
            self.delegate.setStatus(text: "\(stations.count)", color: UIColor.red)
        }).catch(execute: { error -> Void in
            self.delegate.setStatus(error: error)
        })
    }
}
