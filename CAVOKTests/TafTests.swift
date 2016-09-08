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
}
