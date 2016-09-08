//
//  Helper.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 08.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import XCTest
import RealmSwift

open class ObservationTestCase: XCTestCase {
    
    override open func setUp() {
        super.setUp()
        
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
    }
    
    func getDateFor(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd hh:mm"
        
        var cal = NSCalendar.current
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        var comps = cal.dateComponents([.year, .month, .minute], from:Date())
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        
        let date = cal.date(from: comps)!
        if date > Date() {
            return cal.date(byAdding: .month, value: -1, to: date)!
        }
        return date
    }
}
