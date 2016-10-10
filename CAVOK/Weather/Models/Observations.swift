//
//  Observations.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 24/09/2016.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

private typealias ObservationSlot = (slot: Timeslot, observations: [Observation])

struct ObservationGroups {
    let timeslots: [Timeslot]
    let frames: [[Observation]]
    let selectedFrame: Int?
    
    var count: Int {
        return frames.count
    }
}

class Observations {
    
    private let metars: [Metar]
    private let tafs: [Taf]
    
    init(metars: [Metar], tafs: [Taf]) {
        self.metars = metars
        self.tafs = tafs
    }
    
    private func slotDate(date: Date) -> Date {
        let min = Calendar.current.component(.minute, from: date)
        let offset = -(min + 10) % 30
        return Calendar.current.date(byAdding: .minute, value: offset, to: date)!
    }
    
    private func slot(date: Date, title: String? = nil) -> Timeslot {
        return Timeslot(date: date, color: ColorRamp.color(for: date, alpha: 0.2), title: title)
    }

    // group metars into half hour time slots starting every 20 and 50 past
    private func groupMetars() -> [ObservationSlot] {
        let grouped = metars.reduce([Date: [Observation]]()) { (res, item) in
            let slot = self.slotDate(date: item.datetime)
            
            var res = res
            if case nil = res[slot]?.append(item) {
                res[slot] = [item]
            }
            return res
        }
        
        return [Date](grouped.keys).sorted().suffix(6).map { key in
            return (slot(date: key), grouped[key]!)
        }
    }
    
    private func groupTafs() -> [ObservationSlot] {
        if tafs.isEmpty {
            return []
        } else {
            return [(slot(date: Date.distantFuture, title: "TAF"), tafs)]
        }
    }
    
    func group() -> ObservationGroups {
        let metars = groupMetars()
        let tafs = groupTafs()
        let all = metars + tafs
        
        let selectedFrame: Int? = metars.isEmpty ? nil : metars.count - 1
        
        return ObservationGroups(timeslots: all.map { $0.slot }, frames: all.map { $0.observations }, selectedFrame: selectedFrame)
    }
}
