//
//  TafTests.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 07.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import XCTest
@testable import CAV_OK

class TafTests : ObservationTestCase {
    
    func testTaf() {
        let taf = Taf()
        taf.now = getDateFor(2019, 10, 31, 0, 0)
        taf.parse(raw: "TAF EFHK 121430Z 1215/1315 24008KT CAVOK TEMPO 1305/1313 SHRA BKN012 BKN020CB PROB30 TEMPO 1305/1312 6000 TSRA")
        
        XCTAssertEqual(taf.datetime, getDateFor(2019, 10, 12, 14, 30))
        XCTAssertEqual(taf.from, getDateFor(2019, 10, 12, 15, 00))
        XCTAssertEqual(taf.to, getDateFor(2019, 10, 13, 15, 00))
        
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
        taf.now = getDateFor(2019, 10, 31, 0, 0)
        taf.parse(raw: "TAF COR EFTU 091810Z 0918/1018 18003KT CAVOK BECMG 0923/1002 4000 BR BKN004 TEMPO 1003/1007 0500 FG BECMG 1007/1009 9999 FEW010 BECMG 1010/1012 25010KT")
        
        XCTAssertEqual(taf.datetime, getDateFor(2019, 10, 9, 18, 10))
        XCTAssertEqual(taf.from, getDateFor(2019, 10, 9, 18, 00))
        XCTAssertEqual(taf.to, getDateFor(2019, 10, 10, 18, 00))
        
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
        taf.now = getDateFor(2019, 10, 31, 0, 0)
        taf.parse(raw: "TAF ENGM 2318/2418 32005KT 9999 FEW005 PROB30 2319/2408 2000 BCFG BKN002 BECMG 2410/2412 19010KT")
        
        XCTAssertEqual(taf.datetime, getDateFor(2019, 10, 23, 18, 00))
        XCTAssertEqual(taf.from, taf.datetime)
        XCTAssertEqual(taf.to, getDateFor(2019, 10, 24, 18, 00))
        
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
    
    func testTafMidnight() {
        let taf = Taf()
        taf.now = getDateFor(2019, 10, 31, 0, 0)
        taf.parse(raw: "TAF EETN 242310Z 2500/2524 21005KT 9999 BKN025 PROB40 TEMPO 2520/2524 2000 BR BKN003")
        
        XCTAssertEqual(taf.datetime, getDateFor(2019, 10, 24, 23, 10))
        XCTAssertEqual(taf.from, getDateFor(2019, 10, 25, 00, 00))
        XCTAssertEqual(taf.to, getDateFor(2019, 10, 26, 00, 00))
        
        XCTAssertEqual(taf.identifier, "EETN")
        
        let wind = taf.wind
        XCTAssertEqual(wind.direction!, 210)
        XCTAssertEqual(wind.speed!, 5)
        XCTAssertNil(wind.gust)
        XCTAssertNil(wind.variability)
        XCTAssertEqual(taf.visibility.value!, 9999)
        XCTAssertEqual(taf.weather!, "")
        XCTAssertEqual(taf.clouds!, "BKN025")
        
        XCTAssertEqual(taf.cloudHeight.value!, 2500);
        XCTAssertEqual(taf.conditionEnum, WeatherConditions.MVFR);
        
        XCTAssertEqual(taf.supplements!, "PROB40 TEMPO 2520/2524 2000 BR BKN003")
    }
    
    func testTafWithoutTafPrefix() {
        let taf = Taf()
        taf.now = getDateFor(2019, 10, 31, 0, 0)
        taf.parse(raw: "ENVA 2718/2818 15008KT 9999 FEW050 SCT080 PROB40 TEMPO 2718/2721 16015G25KT PROB30 TEMPO 2810/2818 SHRA SCT025CB")
        
        XCTAssertEqual(taf.datetime, getDateFor(2019, 10, 27, 18, 00))
        XCTAssertEqual(taf.from, taf.datetime)
        XCTAssertEqual(taf.to, getDateFor(2019, 10, 28, 18, 00))
        
        XCTAssertEqual(taf.identifier, "ENVA")
        
        let wind = taf.wind
        XCTAssertEqual(wind.direction!, 150)
        XCTAssertEqual(wind.speed!, 8)
        XCTAssertNil(wind.gust)
        XCTAssertNil(wind.variability)
        XCTAssertEqual(taf.visibility.value!, 9999)
        XCTAssertEqual(taf.weather!, "")
        XCTAssertEqual(taf.clouds!, "FEW050 SCT080")
        
        XCTAssertEqual(taf.cloudHeight.value!, 5000);
        XCTAssertEqual(taf.conditionEnum, WeatherConditions.VFR);
        
        XCTAssertEqual(taf.supplements!, "PROB40 TEMPO 2718/2721 16015G25KT PROB30 TEMPO 2810/2818 SHRA SCT025CB")
    }
    
    func testTafWithNilValidity() {
        let taf = Taf()
        taf.now = getDateFor(2019, 10, 31, 0, 0)
        taf.parse(raw: "TAF HLLT 271700Z NIL TAF HLLM 271700Z 2718/2818 03012KT 9999 FEW030 BECMG 2800/2802 VRB02KT 8000 NSC BECMG 2806/2808 02010KT 9999 FEW030 BECMG 2812/2814 06012KT CAVOK")
        
        XCTAssertEqual(taf.datetime, getDateFor(2019, 10, 27, 17, 00))
        XCTAssertEqual(taf.from, taf.datetime)
        XCTAssertEqual(taf.to, getDateFor(2019, 10, 28, 17, 00))
    }
    
    func testTafFromPreviousMonth() {
        let taf = Taf()
        taf.now = getDateFor(2019, 11, 1, 6, 0)
        taf.parse(raw: "TAF EEEI 312330Z 0100/0124 29010KT 9999 BKN035 PROB30 TEMPO 0106/0112 5000 RA BKN015 BECMG 0115/0117 19008KT")
        
        XCTAssertEqual(taf.datetime, getDateFor(2019, 10, 31, 23, 30))
        XCTAssertEqual(taf.from, getDateFor(2019, 11, 1, 00, 00))
        XCTAssertEqual(taf.to, getDateFor(2019, 11, 1, 24, 00))
    }

    func testTafOverlappingMonth() {
        let taf = Taf()
        taf.now = getDateFor(2019, 11, 1, 6, 0)
        taf.parse(raw: "TAF EEEI 311230Z 3112/0112 29010KT 9999 BKN035 PROB30 TEMPO 0106/0112 5000 RA BKN015 BECMG 0115/0117 19008KT")
        
        XCTAssertEqual(taf.datetime, getDateFor(2019, 10, 31, 12, 30))
        XCTAssertEqual(taf.from, getDateFor(2019, 10, 31, 12, 00))
        XCTAssertEqual(taf.to, getDateFor(2019, 11, 1, 12, 00))
    }
    
    func testTafFromPreviousYear() {
        let taf = Taf()
        taf.now = getDateFor(2020, 1, 1, 0, 0)
        taf.parse(raw: "TAF EEEI 312330Z 0100/0124 29010KT 9999 BKN035 PROB30 TEMPO 0106/0112 5000 RA BKN015 BECMG 0115/0117 19008KT")
        
        XCTAssertEqual(taf.datetime, getDateFor(2019, 12, 31, 23, 30))
        XCTAssertEqual(taf.from, getDateFor(2020, 1, 1, 00, 00))
        XCTAssertEqual(taf.to, getDateFor(2020, 1, 2, 00, 00))
    }

}
