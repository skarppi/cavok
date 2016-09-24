//
//  ObservationGroup.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 24/09/2016.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class ObservationGroup {
    
    private class func slot(date: Date) -> Date {
        let min = Calendar.current.component(.minute, from: date)
        let offset = -(min + 10) % 30
        return Calendar.current.date(byAdding: .minute, value: offset, to: date)!
    }
    
    // group observations into half hour time slots starting every 20 and 50 past
    class func group(observations: [Observation]) -> [(slot: Date, observations: [Observation])] {
        
        var groups = observations.reduce([Date: [Observation]]()) { (res, item) in
            let slot = self.slot(date: item.datetime)
            
            var res = res
            if case nil = res[slot]?.append(item) {
                res[slot] = [item]
            }
            return res
        }
        
        let slots = [Date](groups.keys).sorted().suffix(6)
        return slots.map { slot in
            return (slot, groups[slot]!)
        }
    }
}
