//
//  TimeslotView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 27.3.2021.
//

import SwiftUI

struct TimeslotDrawerView: View {
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var state: TimeslotState

    @GestureState var cursor = CGPoint.zero

    var body: some View {
        VStack(spacing: 4) {

            TimelineView(.everyMinute) { timeline in
                TimeslotStatus(slot: state.slots[safe: state.selectedFrame], now: timeline.date)
            }

            timeline().gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .updating($cursor) { (value, state, _) in
                        state = value.location
                    })
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func timeline() -> some View {
        HStack(spacing: 0) {
            ForEach(Array(state.slots.enumerated()), id: \.element) { (index, slot) in
                Text(slot.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(EdgeInsets(top: 10, leading: 3, bottom: 10, trailing: 3))
                    .background(
                        Rectangle().fill(
                            slot.color
                                .opacity(colorScheme == .dark ? 0.9 : 0.4)
                        )
                    )
                    .border(state.selectedFrame == index
                            ? (colorScheme == .dark ? Color.white : Color.black)
                            : Color.clear)
                    .background(self.rectReader(index: index))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(Color.gray, lineWidth: 1))
    }

    func rectReader(index: Int) -> some View {
        return GeometryReader { (geometry) -> AnyView in
            if geometry.frame(in: .global).contains(self.cursor) {
                DispatchQueue.main.async {
                    state.selectedFrame = index
                }
            }
            return AnyView(Rectangle().fill(Color.clear))
        }
    }
}

struct TimeslotStatus: View {
    let slot: Timeslot?

    let now: Date

    var body: some View {
        Text(status())
            .font(.body)
            .padding(.leading, 15)
            .foregroundColor(ColorRamp.color(forMinutes: slot?.date.minutesSinceNow ?? Int.max))
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .background(Color(.secondarySystemFill))
            .cornerRadius(10)
    }

    private func status() -> String {
        guard let slot = slot else {
            return "No Data"
        }

        let timestamps = Set(slot.observations.map({ $0.datetime }))

        guard let oldest = timestamps.min() else { return "-" }
        guard let latest = timestamps.max() else { return "-" }

        let oldestMinutes = oldest.minutesSince(date: now)
        let latestMinutes = latest.minutesSince(date: now)

        if oldest == latest || oldestMinutes >= 120 {
            return "\(Date.since(minutes: latestMinutes)) ago"
        } else if oldestMinutes < 60 {
            return "\(latestMinutes)-\(Date.since(minutes: oldestMinutes)) ago"
        } else {
            return "\(Date.since(minutes: latestMinutes)) - \(Date.since(minutes: oldestMinutes)) ago"
        }
    }
}

struct TimeslotDraverView_Previews: PreviewProvider {

    static func state() -> TimeslotState {
        let state = TimeslotState()
        state.slots = [
            Timeslot(date: Date(), observations: []),
            Timeslot(date: Date().addMinutes(30), observations: [])
        ]

        state.slots[0].color = Color.red
        state.slots[1].color = Color.blue

        state.selectedFrame = 0

        return state
    }

    static var previews: some View {
        TimeslotDrawerView()
            .environmentObject(state())
    }
}
