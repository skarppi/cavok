//
//  Timeslot.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 27/09/2016.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import SwiftUI

public struct Timeslot {
    let date: Date

    let title: String

    let observations: [Observation]

    var color: Color = Color.clear

    init(tafs: [Taf]) {
        self.date = Date.distantFuture
        self.title = "TAF"
        self.observations = tafs
    }

    init(date: Date, observations: [Observation]) {
        self.date = date
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        self.title = formatter.string(from: date)
        self.observations = observations
    }

    var isForecast: Bool {
        return observations.first?.isKind(of: Taf.self) ?? false
    }
}

// Date is unique enough
extension Timeslot: Hashable {
    public static func == (lhs: Timeslot, rhs: Timeslot) -> Bool {
        return lhs.date == rhs.date
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(date)
    }
}
