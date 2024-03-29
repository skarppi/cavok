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
@testable import CAV_OK

class WeatherServiceTests: XCTestCase {

    let weatherServer = WeatherServer()

    override func setUp() {
        super.setUp()
//        let coordinates = NSMutableDictionary()
//        coordinates.setObject(60.0, forKey: "minLat")
//        coordinates.setObject(65.0, forKey: "maxLat")
//        coordinates.setObject(20.0, forKey: "minLon")
//        coordinates.setObject(25.0, forKey: "maxLon")
//
//        coordinates.setObject(200000.0, forKey: "radius")
//
//        let defaults = NSUserDefaults.standardUserDefaults()
//        defaults.setObject(coordinates, forKey: "coordinates")
//        defaults.synchronize()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testStations() async throws {
        let stations = try await weatherServer.refreshStations()

        let stationCount = try WeatherServer.query.getStationCount()
        XCTAssertEqual(stationCount, 12+18)

        XCTAssertEqual(stations.count, 12+18)
    }

    func testStationsWithMetars() async throws {
        // let station = try await weatherServer.fetchStation(station: "EFNU")!

        let metar = try await weatherServer.fetchLatest(station: AtisService.efnu)
        XCTAssertEqual("MOI", metar?.raw)

    }
    /*
     func testPerformanceExample() {
     // This is an example of a performance test case.
     self.measureBlock() {
     // Put the code you want to measure the time of here.
     }
     }*/

}
