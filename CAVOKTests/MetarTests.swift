//
//  MetarTests.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 04.11.12.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import XCTest
import CAVOK

class MetarTests : ObservationTestCase {
    
    func testAwsMetar() {
        let date = getDateFor(01, 20, 20, monthOffset: true)
        
        let metar = Metar()
        metar.parse(raw: "ILZU 012020Z AUTO 31009KT 9999 FEW036 03/02 Q1012 RMK QFE1011 NOCBANALYSIS=")
        XCTAssertEqual(metar.type, "AUTO")
        XCTAssertEqual(metar.datetime, date)
        
        let wind = metar.wind
        XCTAssertEqual(wind.direction!, 310)
        XCTAssertEqual(wind.speed!, 9)
        XCTAssertNil(wind.gust)
        XCTAssertNil(wind.variability)
        XCTAssertEqual(metar.visibility.value!, 9999)
        XCTAssertNil(metar.runwayVisualRange)
        XCTAssertEqual(metar.weather!, "")
        XCTAssertEqual(metar.clouds!, "FEW036")
        XCTAssertEqual(metar.temperature.value!, 3)
        
        XCTAssertEqual(metar.dewPoint.value!, 2)
        XCTAssertEqual(metar.altimeter.value!, 1012)
        XCTAssertEqual(metar.supplements!, "RMK QFE1011 NOCBANALYSIS=")
    }
    
    func testSwedenMetar() {
        let date = getDateFor(01, 10, 20, monthOffset: true)
        
        let metar = Metar()
        metar.parse(raw: "ESNN 011020Z AUTO 35002KT 9999NDV BKN089/// 03/02 Q0999 R16/19//81")
        XCTAssertEqual(metar.type, "AUTO");
        XCTAssertEqual(metar.datetime, date);
        let wind = metar.wind
        XCTAssertEqual(wind.direction!, 350);
        XCTAssertEqual(wind.speed!, 2);
        XCTAssertNil(wind.gust);
        XCTAssertNil(wind.variability);
        XCTAssertEqual(metar.visibility.value!, 9999);
        XCTAssertNil(metar.runwayVisualRange);
        XCTAssertEqual(metar.weather!, "");
        XCTAssertEqual(metar.clouds!, "BKN089///");
        XCTAssertEqual(metar.temperature.value!, 3);
        
        XCTAssertEqual(metar.dewPoint.value!, 2);
        XCTAssertEqual(metar.altimeter.value!, 999);
        XCTAssertEqual(metar.supplements!, "R16/19//81");
        
        XCTAssertEqual(metar.cloudHeight.value!, 8900);
        XCTAssertEqual(metar.visibility.value!, 9999);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.VFR);
    }
    
    func testUsa() {
        let metar = Metar()
        metar.parse(raw: "KIYK 101145Z 21007KT 20SM SKC 06/ A2986 RMK FIRST")
        XCTAssertEqual(metar.altimeter.value!, 1011);
        XCTAssertEqual(metar.temperature.value!, 6);
        XCTAssertNil(metar.dewPoint.value);
        XCTAssertEqual(metar.visibility.value!, 32180);
        
        metar.parse(raw: "KSEE 101215Z AUTO 00000KT 8SM CLR 07/07 A3002 RMK AO2")
        let wind = metar.wind
        XCTAssertEqual(wind.direction!, 0);
        XCTAssertEqual(wind.speed!, 0);
        XCTAssertEqual(metar.cloudHeight.value!, 5000);
        XCTAssertEqual(metar.visibility.value!, 12872);
        XCTAssertEqual(metar.temperature.value!, 7);
        XCTAssertEqual(metar.dewPoint.value!, 7);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.VFR);
        
        metar.parse(raw: "KNYL 101155Z 35007KT 10SM FEW100 12/03 A2993 RMK AO2 SLP135 T01170028 10144 20111 53015 $")
        XCTAssertEqual(metar.cloudHeight.value!, 10000);
    }
    
    func testUkMetar() {
        let metar = Metar()
        metar.parse(raw: "EGKB 111020Z 00000KT CAVOK 06/04 Q1011")
        let wind = metar.wind
        XCTAssertEqual(wind.direction!, 0);
        XCTAssertEqual(wind.speed!, 0);
        XCTAssertEqual(metar.temperature.value!, 6);
        XCTAssertEqual(metar.dewPoint.value!, 4);
        XCTAssertEqual(metar.altimeter.value!, 1011);
        
        XCTAssertEqual(metar.cloudHeight.value!, 5000);
        XCTAssertEqual(metar.visibility.value!, 10000);
    }
    
    func testNegativeTemperatures() {
        let metar = Metar()
        metar.parse(raw: "ILZU 012120Z 31009KT 9999 FEW036 03/M02")
        XCTAssertEqual(metar.temperature.value!, 3);
        XCTAssertEqual(metar.dewPoint.value!, -2);
        
        metar.parse(raw: "ILZU 012120Z AUTO 9999 FEW036 M03/02")
        XCTAssertEqual(metar.temperature.value!, -3);
        XCTAssertEqual(metar.dewPoint.value!, 2);
        
        metar.parse(raw: "ILZU 012120Z AUTO 9999 FEW036 M03/M02")
        XCTAssertEqual(metar.temperature.value!, -3);
        XCTAssertEqual(metar.dewPoint.value!, -2);
    }
    
    func testAwsTemperatureWithoutWind() {
        let metar = Metar()
        metar.parse(raw: "ILZM 150730Z AUTO /////KT 9999 SCT004 OVC014 03/02 Q1035=")
        XCTAssertEqual(metar.temperature.value!, 3);
        XCTAssertEqual(metar.dewPoint.value!, 2);
    }
    
    func testVFRConditions() {
        let metar = Metar()
        metar.parse(raw: "ILZU 012120Z AUTO 31009KT 9999 OVC031")
        XCTAssertEqual(metar.cloudHeight.value!, 3100);
        XCTAssertEqual(metar.visibility.value!, 9999);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.VFR);
        
        metar.parse(raw: "ILZU 012120Z AUTO 31009KT 8000 BKN030")
        XCTAssertEqual(metar.cloudHeight.value!, 3000);
        XCTAssertEqual(metar.visibility.value!, 8000);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.VFR);
        
        metar.parse(raw: "ILZU 012120Z AUTO 31009KT 8000 FEW010 BKN085")
        XCTAssertEqual(metar.cloudHeight.value!, 1000);
        XCTAssertEqual(metar.visibility.value!, 8000);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.VFR);
        
        metar.parse(raw: "ILZU 012120Z AUTO 31009KT 8000 FG BKN030")
        XCTAssertEqual(metar.cloudHeight.value!, 100);
        XCTAssertEqual(metar.visibility.value!, 8000);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.VFR);
    }
    
    func testCavokConditions() {
        let metar = Metar()
        metar.parse(raw: "ILZU 012120Z AUTO 31009KT CAVOK")
        XCTAssertEqual(metar.cloudHeight.value!, 5000);
        XCTAssertEqual(metar.visibility.value!, 10000);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.VFR);
        
        metar.parse(raw: "ILZU 012120Z AUTO 31009KT 8500 CAVOK")
        XCTAssertEqual(metar.cloudHeight.value!, 5000);
        XCTAssertEqual(metar.visibility.value!, 8500);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.VFR);
        
        metar.parse(raw: "ILZU 012120Z AUTO 31009KT 8888 FEW001")
        XCTAssertEqual(metar.cloudHeight.value!, 100);
        XCTAssertEqual(metar.visibility.value!, 8888);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.VFR);
    }
    
    func testMarginalVFRConditions() {
        let metar = Metar()
        metar.parse(raw: "ILZU 012120Z AUTO 31009KT 9999 OVC029")
        XCTAssertEqual(metar.cloudHeight.value!, 2900);
        XCTAssertEqual(metar.visibility.value!, 9999);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.MVFR);
        
        metar.parse(raw: "ILZU 012120Z AUTO 31009KT 8000 BKN015")
        XCTAssertEqual(metar.cloudHeight.value!, 1500);
        XCTAssertEqual(metar.visibility.value!, 8000);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.MVFR);
    }
    
    func testIFRConditions() {
        let metar = Metar()
        metar.parse(raw: "ILZU 012120Z AUTO 31009KT 9999 OVC010")
        XCTAssertEqual(metar.cloudHeight.value!, 1000);
        XCTAssertEqual(metar.visibility.value!, 9999);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.IFR);
        
        metar.parse(raw: "ILZU 012120Z AUTO 31009KT 3000 BKN030")
        XCTAssertEqual(metar.cloudHeight.value!, 3000);
        XCTAssertEqual(metar.visibility.value!, 3000);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.IFR);
        
        metar.parse(raw: "ILZU 012120Z AUTO 31009KT FG BKN002")
        XCTAssertEqual(metar.cloudHeight.value!, 100);
        XCTAssertNil(metar.visibility.value);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.IFR);
        
        metar.parse(raw: "ILZU 012120Z AUTO 31009KT FG BKN000")
        XCTAssertEqual(metar.cloudHeight.value!, 0);
        XCTAssertNil(metar.visibility.value);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.IFR);
    }
    
    func testVerticalVisibility() {
        let metar = Metar()
        metar.parse(raw: "ILZU 012120Z AUTO 31009KT 9999 VV///")
        XCTAssertEqual(metar.cloudHeight.value!, 100);
        XCTAssertEqual(metar.visibility.value!, 9999);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.IFR);
        
        metar.parse(raw: "ILZU 012120Z AUTO 31009KT 9999 VV015")
        XCTAssertEqual(metar.cloudHeight.value!, 1500);
        XCTAssertEqual(metar.visibility.value!, 9999);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.MVFR);
    }
    
    func testWindVariability() {
        let metar = Metar()
        metar.parse(raw: "EFHF 100550Z AUTO 18009G25KT 140V230 9999 FEW026 OVC047 04/M01 Q1017=")
        let wind = metar.wind
        XCTAssertEqual(wind.direction!, 180);
        XCTAssertEqual(wind.speed!, 9);
        XCTAssertEqual(wind.gust!, 25);
        XCTAssertEqual(wind.variability!, "140V230");
        XCTAssertEqual(metar.cloudHeight.value!, 2600);
        XCTAssertEqual(metar.visibility.value!, 9999);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.VFR);
    }
    
    func testWindVariable() {
        let metar = Metar()
        metar.parse(raw: "EFHF 100550Z AUTO VRB09G25KT 9999 FEW026 OVC047 04/M01 Q1017=")
        let wind = metar.wind
        XCTAssertNil(wind.direction);
        XCTAssertEqual(wind.speed!, 9);
        XCTAssertEqual(wind.gust!, 25);
        XCTAssertNil(wind.variability);
        XCTAssertEqual(metar.cloudHeight.value!, 2600);
        XCTAssertEqual(metar.visibility.value!, 9999);
        XCTAssertEqual(metar.conditionEnum, WeatherConditions.VFR);
    }
}
