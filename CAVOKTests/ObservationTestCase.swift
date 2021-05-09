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

    func getDateFor(_ year: Int = 2019, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd hh:mm"

        var cal = NSCalendar.current
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let comps = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        let date = cal.date(from: comps)!
        return date
    }
}
