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
        let date = getDateFor(12, 14, 30)
        
        let taf = Taf()
        taf.parse(raw: "TAF EFHK 121430Z 1215/1315 24008KT CAVOK TEMPO 1305/1313 SHRA BKN012 BKN020CB PROB30 TEMPO 1305/1312 6000 TSRA")
        
        XCTAssertEqual(taf.datetime, date)
        
        let wind = taf.wind
        XCTAssertEqual(wind.direction!, 240)
        XCTAssertEqual(wind.speed!, 8)
        XCTAssertNil(wind.gust)
        XCTAssertNil(wind.variability)
        XCTAssertEqual(taf.visibility.value!, 10000)
        XCTAssertEqual(taf.weather!, "")
        XCTAssertEqual(taf.clouds!, "CAVOK")
        
        XCTAssertEqual(taf.supplements!, "TEMPO 1305/1313 SHRA BKN012 BKN020CB PROB30 TEMPO 1305/1312 6000 TSRA")
    }
    
    func testTafCor() {
        let date = getDateFor(9, 18, 10)
        
        let taf = Taf()
        taf.parse(raw: "TAF COR EFTU 091810Z 0918/1018 18003KT CAVOK BECMG 0923/1002 4000 BR BKN004 TEMPO 1003/1007 0500 FG BECMG 1007/1009 9999 FEW010 BECMG 1010/1012 25010KT")
        
        XCTAssertEqual(taf.datetime, date)
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
        
        XCTAssertEqual(taf.supplements!, "BECMG 0923/1002 4000 BR BKN004 TEMPO 1003/1007 0500 FG BECMG 1007/1009 9999 FEW010 BECMG 1010/1012 25010KT")
    }
}
