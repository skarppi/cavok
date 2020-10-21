//
//  Date+Additions.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 30.10.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

//https://github.com/pNre/ExSwift/blob/master/ExSwift/NSDate.swift
public extension Date {
    
    // MARK:  NSDate Manipulation
    
    /**
     Returns a new NSDate object representing the date calculated by adding the amount specified to self date
     
     - parameter seconds: number of seconds to add
     - parameter minutes: number of minutes to add
     - parameter hours: number of hours to add
     - parameter days: number of days to add
     - parameter weeks: number of weeks to add
     - parameter months: number of months to add
     - parameter years: number of years to add
     - returns: the NSDate computed
     */
    func add(_ seconds:Int=0, minutes:Int = 0, hours:Int = 0, days:Int = 0, weeks:Int = 0, months:Int = 0, years:Int = 0) -> Date {
        let calendar = Calendar.current
        var date = calendar.date(byAdding: .second, value: seconds, to: self)!
        date = calendar.date(byAdding: .minute, value: minutes, to: date)!
        date = calendar.date(byAdding: .day, value: days, to: date)!
        date = calendar.date(byAdding: .hour, value: hours, to: date)!
        date = calendar.date(byAdding: .weekOfYear, value: weeks, to: date)!
        date = calendar.date(byAdding: .month, value: months, to: date)!
        date = calendar.date(byAdding: .year, value: years, to: date)!
        return date
    }
    
    /**
     Returns a new NSDate object representing the date calculated by adding an amount of seconds to self date
     
     - parameter seconds: number of seconds to add
     - returns: the NSDate computed
     */
    func addSeconds (_ seconds: Int) -> Date {
        return add(seconds)
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
    var minutes : Int {
        get {
            return getComponent(Calendar.Component.minute)
        }
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
    func isAfter(_ date: Date) -> Bool{
        return (self.compare(date) == ComparisonResult.orderedDescending)
    }
    
    /**
     Checks if self is before input NSDate
     
     - parameter date: NSDate to compare
     - returns: True if self is before the input NSDate, false otherwise
     */
    func isBefore(_ date: Date) -> Bool{
        return (self.compare(date) == ComparisonResult.orderedAscending)
    }
    
    /**
     Checks if self is between two NSDates
     
     - parameter inclusiveMin: self must be greater or equal NSDate
     - parameter exclusiveMax: self must be less than NSDate
     - returns: True if self is between NSDates, false otherwise
     */
    func isBetween(_ inclusiveMin: Date, exclusiveMax: Date) -> Bool{
        return !isBefore(inclusiveMin) && isBefore(exclusiveMax)
    }
    
    func isInFuture() -> Bool {
        return self.isAfter(Date())
    }
}
