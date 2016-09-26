//
//  WeatherServerTests.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 26/09/2016.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

import UIKit
import XCTest
import CAVOK
import PromiseKit

class WeatherServiceTests: XCTestCase {
    
    let weatherServer = WeatherService()
    
    override func setUp() {
        super.setUp()
        
        let coordinates = NSMutableDictionary()
        coordinates.setObject(60.0, forKey:"minLat")
        coordinates.setObject(65.0, forKey:"maxLat")
        coordinates.setObject(20.0, forKey:"minLon")
        coordinates.setObject(25.0, forKey:"maxLon")
        
        coordinates.setObject(200000.0, forKey:"radius")
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(coordinates, forKey:"coordinates")
        defaults.synchronize()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStations() {
        let expectation = self.expectationWithDescription("fetch stations")
        weatherServer.refreshStations().then { (stations) -> Void in
            let stationCount = self.weatherServer.getStationCount()
            XCTAssertEqual(stationCount, 12+18)
            
            XCTAssertEqual(stations.count, 12+18)
            
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testStationsWithMetars() {
        let stationCount = self.weatherServer.getStationCount()
        XCTAssertEqual(stationCount, 12+18)
        
        let expectation = self.expectationWithDescription("fetch metars")
        weatherServer.refreshObservations().then { metars in
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(15.0, handler: nil)
        
        let metars = weatherServer.observations(Metar.self)
        
        XCTAssertEqual(metars.count, 8+18);
    }
    /*
     func testPerformanceExample() {
     // This is an example of a performance test case.
     self.measureBlock() {
     // Put the code you want to measure the time of here.
     }
     }*/
    
}
