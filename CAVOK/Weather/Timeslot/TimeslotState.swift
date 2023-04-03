//
//  TimeslotState.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 31.3.2021.
//

import SwiftUI
import Combine

// Our observable object class
@MainActor class TimeslotState: ObservableObject {
    var slots: [Timeslot] = []

    var count: Int {
        return slots.count
    }

    @Published var selectedFrame: Int?

    func reset(observations: Observations) {
        let metars = groupMetars(metars: observations.metars)
        let tafs = groupTafs(tafs: observations.tafs)
        slots = metars + tafs
        selectedFrame = metars.isEmpty ? nil : metars.count - 1
    }

    private func nearestHalfHour(date: Date) -> Date {
        let minute = Calendar.current.component(.minute, from: date)
        let offset = -minute % 30
        return Calendar.current.date(byAdding: .minute, value: offset, to: date)!
    }

    // group metars into half hour time slots
    private func groupMetars(metars: [Metar]) -> [Timeslot] {
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

    private func groupTafs(tafs: [Taf]) -> [Timeslot] {
        if tafs.isEmpty {
            return []
        } else {
            return [
                Timeslot(tafs: tafs)
            ]
        }
    }

    func update(color: Color, at index: Int) {
        slots[index].color = color
    }
}
