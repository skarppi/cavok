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

    @State var status: String = "Loading"

    @State var statusColor = Color.primary

    @GestureState var cursor = CGPoint.zero

    let updateTimestampsTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 4) {

            Text(status)
                .font(.body)
                .padding(.leading, 15)
                .foregroundColor(statusColor)
                .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                .background(Color(.secondarySystemFill))
                .cornerRadius(10)

            timeline().gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .updating($cursor) { (value, state, _) in
                        state = value.location
                    })
        }
        .padding(.top, 4)
        .onReceive(state.$selectedFrame) { index in
            refreshStatus(slot: state.slots[safe: index])
        }
        .onChange(of: state.slots) { slots in
            refreshStatus(slot: slots[safe: state.selectedFrame])
        }
        .onReceive(updateTimestampsTimer) { _ in
            refreshStatus(slot: state.slots[safe: state.selectedFrame])
        }
        .onAppear {
            refreshStatus(slot: state.slots[safe: state.selectedFrame])
        }
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

    private func status(slot: Timeslot) -> String {
        let timestamps = Set(slot.observations.map({ $0.datetime }))

        guard let oldest = timestamps.min() else { return "-" }
        guard let latest = timestamps.max() else { return "-" }

        let oldestMinutes = oldest.minutesSinceNow
        let latestMinutes = latest.minutesSinceNow

        if oldest == latest || oldestMinutes >= 120 {
            return Date.since(minutes: latestMinutes)
        } else if oldestMinutes < 60 {
            return "\(latestMinutes)-\(Date.since(minutes: oldestMinutes))"
        } else {
            return "\(Date.since(minutes: latestMinutes)) - \(Date.since(minutes: oldestMinutes))"
        }
    }

    private func refreshStatus(slot: Timeslot?) {
        guard let slot = slot else {
            self.status = "No Data"
            return
        }

        let status = status(slot: slot)

        self.status = "\(status) ago"
        self.statusColor = ColorRamp.color(forMinutes: slot.date.minutesSinceNow)
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
