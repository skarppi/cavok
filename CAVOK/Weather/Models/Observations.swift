//
//  Observations.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 24/09/2016.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

struct ObservationGroups {
    let timeslots: [Timeslot]
    let selectedFrame: Int?

    var count: Int {
        return timeslots.count
    }
}

class Observations {

    let metars: [Metar]
    let tafs: [Taf]

    init(metars: [Metar], tafs: [Taf]) {
        self.metars = metars
        self.tafs = tafs
    }

    private func nearestHalfHour(date: Date) -> Date {
        let minute = Calendar.current.component(.minute, from: date)
        let offset = -minute % 30
        return Calendar.current.date(byAdding: .minute, value: offset, to: date)!
    }

    // group metars into half hour time slots
    private func groupMetars() -> [Timeslot] {
        // sort latest first
        let grouped = metars.reversed().reduce([Date: [Observation]]()) { (res, item) in
            let slot = nearestHalfHour(date: item.datetime)
            let existingItems = res[slot] ?? []

            guard !existingItems.contains(where: { $0.station == item.station }) else {
                // newer observation already exists for the station
                return res
            }

            var res = res
            if case nil = res[slot]?.append(item) {
                res[slot] = [item]
            }
            return res
        }

        return [Date](grouped.keys).sorted().suffix(6).map { date in
            return Timeslot(date: date, observations: grouped[date]!)
        }
    }

    private func groupTafs() -> [Timeslot] {
        if tafs.isEmpty {
            return []
        } else {
            return [
                Timeslot(tafs: tafs)
            ]
        }
    }

    func group() -> ObservationGroups {
        let metars = groupMetars()
        let tafs = groupTafs()
        let all = metars + tafs

        let selectedFrame: Int? = metars.isEmpty ? nil : metars.count - 1

        return ObservationGroups(timeslots: all, selectedFrame: selectedFrame)
    }
}
