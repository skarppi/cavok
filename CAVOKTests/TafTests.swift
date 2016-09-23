//
//  TafTests.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 07.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import XCTest
import CAVOK

class TafTests : ObservationTestCase {
    
    func testTaf() {
        let taf = Taf()
        taf.parse(raw: "TAF EFHK 121430Z 1215/1315 24008KT CAVOK TEMPO 1305/1313 SHRA BKN012 BKN020CB PROB30 TEMPO 1305/1312 6000 TSRA")
        
        XCTAssertEqual(taf.datetime, getDateFor(12, 14, 30))
        XCTAssertEqual(taf.from, getDateFor(12, 15, 00))
        XCTAssertEqual(taf.to, getDateFor(13, 15, 00))
        
        XCTAssertEqual(taf.identifier, "EFHK")
        
        let wind = taf.wind
        XCTAssertEqual(wind.direction!, 240)
        XCTAssertEqual(wind.speed!, 8)
        XCTAssertNil(wind.gust)
        XCTAssertNil(wind.variability)
        XCTAssertEqual(taf.visibility.value!, 10000)
        XCTAssertEqual(taf.weather!, "")
        XCTAssertEqual(taf.clouds!, "CAVOK")
        
        XCTAssertEqual(taf.cloudHeight.value!, 5000);
        XCTAssertEqual(taf.conditionEnum, WeatherConditions.VFR);
        
        XCTAssertEqual(taf.supplements!, "TEMPO 1305/1313 SHRA BKN012 BKN020CB PROB30 TEMPO 1305/1312 6000 TSRA")
    }
    
    func testTafCor() {
        let taf = Taf()
        taf.parse(raw: "TAF COR EFTU 091810Z 0918/1018 18003KT CAVOK BECMG 0923/1002 4000 BR BKN004 TEMPO 1003/1007 0500 FG BECMG 1007/1009 9999 FEW010 BECMG 1010/1012 25010KT")
        
        XCTAssertEqual(taf.datetime, getDateFor(9, 18, 10))
        XCTAssertEqual(taf.from, getDateFor(9, 18, 00))
        XCTAssertEqual(taf.to, getDateFor(10, 18, 00))
        
        XCTAssertEqual(taf.identifier, "EFTU")
        XCTAssertEqual(taf.type, "COR")
        
        let wind = taf.wind
        XCTAssertEqual(wind.direction!, 180)
        XCTAssertEqual(wind.speed!, 3)
        XCTAssertNil(wind.gust)
        XCTAssertNil(wind.variability)
        XCTAssertEqual(taf.visibility.value!, 10000)
        XCTAssertEqual(taf.weather!, "")
        XCTAssertEqual(taf.clouds!, "CAVOK")
        
        XCTAssertEqual(taf.cloudHeight.value!, 5000);
        XCTAssertEqual(taf.conditionEnum, WeatherConditions.VFR);
        
        XCTAssertEqual(taf.supplements!, "BECMG 0923/1002 4000 BR BKN004 TEMPO 1003/1007 0500 FG BECMG 1007/1009 9999 FEW010 BECMG 1010/1012 25010KT")
    }
    
    func testTafWithoutTimestamp() {
        let taf = Taf()
        taf.parse(raw: "TAF ENGM 2318/2418 32005KT 9999 FEW005 PROB30 2319/2408 2000 BCFG BKN002 BECMG 2410/2412 19010KT")
        
        XCTAssertEqual(taf.datetime, getDateFor(23, 18, 00))
        XCTAssertEqual(taf.from, taf.datetime)
        XCTAssertEqual(taf.to, getDateFor(24, 18, 00))
        
        XCTAssertEqual(taf.identifier, "ENGM")
        
        let wind = taf.wind
        XCTAssertEqual(wind.direction!, 320)
        XCTAssertEqual(wind.speed!, 5)
        XCTAssertNil(wind.gust)
        XCTAssertNil(wind.variability)
        XCTAssertEqual(taf.visibility.value!, 9999)
        XCTAssertEqual(taf.weather!, "")
        XCTAssertEqual(taf.clouds!, "FEW005")
        
        XCTAssertEqual(taf.cloudHeight.value!, 500);
        XCTAssertEqual(taf.conditionEnum, WeatherConditions.VFR);
        
        XCTAssertEqual(taf.supplements!, "PROB30 2319/2408 2000 BCFG BKN002 BECMG 2410/2412 19010KT")
    }
}
