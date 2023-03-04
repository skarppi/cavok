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

    func getDateFor(_ day: Int, _ hour: Int, _ minute: Int, month: Int? = nil, year: Int? = nil) -> Date {
        var cal = Calendar.current
        cal.timeZone = TimeZone(secondsFromGMT: 0)!

        let comps = DateComponents(year: year ?? cal.component(.year, from: Date()),
                                   month: month ?? cal.component(.month, from: Date()),
                                   day: day, hour: hour, minute: minute)
        let date = cal.date(from: comps)!
        return date
    }
}
