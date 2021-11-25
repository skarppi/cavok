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
    @Published var slots: [Timeslot] = [Timeslot(date: Date(), title: "")]

    @Published var selectedIndex = 0

    @Published var status = "Loading"

    @Published var statusColor = Color.primary

    @Published var isLoading = false

    func reset(slots: [Timeslot], selected: Int) {
        self.slots = slots
        selectedIndex = selected
        stopSpinning()
    }

    func setStatus(error: Error) {
        switch error {
        case let Weather.error(msg):
            setStatus(text: msg)
        default:
            print(error)
            setStatus(text: error.localizedDescription)
        }
    }

    func setStatus(text: String?, color: UIColor = UIColor.systemRed) {
        if let text = text {
            statusColor = Color(color)
            status = text
        }
    }

    func update(color: UIColor, at index: Int) {
        slots[index].color = color
    }

    func startSpinning() {
        isLoading = true
    }

    func stopSpinning() {
        withAnimation { isLoading = false }
    }

    func selectedColor() -> Color {
        return Color(slots[selectedIndex].color)
    }
}
