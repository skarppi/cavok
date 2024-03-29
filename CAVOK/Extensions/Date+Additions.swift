//
//  Date+Additions.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 30.10.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

// https://github.com/pNre/ExSwift/blob/master/ExSwift/NSDate.swift
public extension Date {

    // MARK: NSDate Manipulation

    /**
     Returns a new NSDate object representing the date calculated by adding the amount specified to self date

     - parameter seconds: number of seconds to add
     - parameter minutes: number of minutes to add
     - parameter hours: number of hours to add
     - parameter days: number of days to add
     - returns: the NSDate computed
     */
    func add(seconds: Int = 0, minutes: Int = 0, hours: Int = 0, days: Int = 0) -> Date {
        let calendar = Calendar.current
        var date = calendar.date(byAdding: .second, value: seconds, to: self)!
        date = calendar.date(byAdding: .minute, value: minutes, to: date)!
        date = calendar.date(byAdding: .day, value: days, to: date)!
        date = calendar.date(byAdding: .hour, value: hours, to: date)!
        return date
    }

    /**
     Returns a new NSDate object representing the date calculated by adding an amount of seconds to self date

     - parameter seconds: number of seconds to add
     - returns: the NSDate computed
     */
    func addSeconds (_ seconds: Int) -> Date {
        return add(seconds: seconds)
    }

    /**
     Returns a new NSDate object representing the date calculated by adding an amount of minutes to self date

     - parameter minutes: number of minutes to add
     - returns: the NSDate computed
     */
    func addMinutes (_ minutes: Int) -> Date {
        return add(minutes: minutes)
    }

    /**
     Returns a new NSDate object representing the date calculated by adding an amount of hours to self date

     - parameter hours: number of hours to add
     - returns: the NSDate computed
     */
    func addHours(_ hours: Int) -> Date {
        return add(hours: hours)
    }

    /**
     Date minuts
     */
    var minutes: Int {
        return getComponent(Calendar.Component.minute)
    }

    /**
     Returns the value of the NSDate component

     :param: component NSCalendarUnit
     :returns: the value of the component
     */
    func getComponent(_ component: Calendar.Component) -> Int {
        let calendar = NSCalendar.current
        return calendar.component(component, from: self)
    }

    /**
     Checks if self is after input NSDate

     - parameter date: NSDate to compare
     - returns: True if self is after the input NSDate, false otherwise
     */
    func isAfter(_ date: Date) -> Bool {
        return (self.compare(date) == ComparisonResult.orderedDescending)
    }

    /**
     Checks if self is before input NSDate

     - parameter date: NSDate to compare
     - returns: True if self is before the input NSDate, false otherwise
     */
    func isBefore(_ date: Date) -> Bool {
        return (self.compare(date) == ComparisonResult.orderedAscending)
    }

    /**
     Checks if self is between two NSDates

     - parameter inclusiveMin: self must be greater or equal NSDate
     - parameter exclusiveMax: self must be less than NSDate
     - returns: True if self is between NSDates, false otherwise
     */
    func isBetween(_ inclusiveMin: Date, exclusiveMax: Date) -> Bool {
        return !isBefore(inclusiveMin) && isBefore(exclusiveMax)
    }

    func isInFuture() -> Bool {
        return self.isAfter(Date())
    }

    var minutesSinceNow: Int {
        Int(abs(self.timeIntervalSinceNow) / 60)
    }

    func minutesSince(date: Date) -> Int {
        Int(abs(self.timeIntervalSince(date)) / 60)
    }

    func since() -> String {
        Self.since(minutes: self.minutesSinceNow)
    }

    static func since(minutes: Int) -> String {

        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "en")

        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        if minutes < 60*6 {
            formatter.allowedUnits = [.hour, .minute]
        } else {
            formatter.allowedUnits = [.day, .hour]
        }
        formatter.unitsStyle = .brief
        formatter.zeroFormattingBehavior = .dropLeading

        return formatter.string(from: Double(minutes * 60))!
    }
}
