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
    @Published var slots: [Timeslot] = []

    @Published var selectedIndex: Int?

    func reset(slots: [Timeslot], selected: Int) {
        self.slots = slots
        selectedIndex = selected
    }

    func update(color: Color, at index: Int) {
        slots[index].color = color
    }
}
