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
            Capsule()
                .fill(Color.secondary)
                .frame(width: 36, height: 5)

            Text(status)
                .font(.body)
                .padding(.leading, 15)
                .foregroundColor(
                    statusColor.lighter(by: colorScheme == .dark ? 0.4 : 0))
                .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                .background(Color(.secondarySystemFill))
                .cornerRadius(10)

            timeline.gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .updating($cursor) { (value, state, _) in
                        state = value.location
                    })
        }
        .padding(.top, 4)
        .onReceive(state.$selectedIndex) { index in
            refreshStatus(slot: state.slots[safe: index])
        }
        .onChange(of: state.slots) { slots in
            refreshStatus(slot: slots[safe: state.selectedIndex])
        }
        .onReceive(updateTimestampsTimer) { _ in
            refreshStatus(slot: state.slots[safe: state.selectedIndex])
        }
        .onAppear {
            refreshStatus(slot: state.slots[safe: state.selectedIndex])
        }
    }

    private var timeline: some View {
        HStack(spacing: 0) {
            ForEach(Array(state.slots.enumerated()), id: \.element) { (index, slot) in
                Text(slot.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(EdgeInsets(top: 10, leading: 3, bottom: 10, trailing: 3))
                    .background(
                        Rectangle()
                            .fill(Color(slot.color)
                                    .opacity(colorScheme == .dark ? 0.9 : 0.4))
                    )
                    .border(state.selectedIndex == index
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
                    state.selectedIndex = index
                }
            }
            return AnyView(Rectangle().fill(Color.clear))
        }
    }

    private func status(slot: Timeslot) -> String {
        let timestamps = slot.observations.map({ $0.datetime })

        guard let oldest = timestamps.min() else { return "-" }
        guard let latest = timestamps.max() else { return "-" }

        let oldestMinutes = Int(abs(oldest.timeIntervalSinceNow) / 60)
        let latestMinutes = Int(abs(latest.timeIntervalSinceNow) / 60)

        if oldest == latest || oldestMinutes >= 120 {
            return since(minutes: latestMinutes)
        } else if oldestMinutes < 60 {
            return "\(latestMinutes)-\(since(minutes: oldestMinutes))"
        } else {
            return "\(since(minutes: latestMinutes)) - \(since(minutes: oldestMinutes))"
        }
    }

    private func since(minutes: Int) -> String {

        let formatter = DateComponentsFormatter()
        if minutes < 60*6 {
            formatter.allowedUnits = [.hour, .minute]
        } else {
            formatter.allowedUnits = [.day, .hour]
        }
        formatter.unitsStyle = .brief
        formatter.zeroFormattingBehavior = .dropLeading

        return formatter.string(from: Double(minutes * 60))!
    }

    private func refreshStatus(slot: Timeslot?) {
        guard let slot = slot else {
            self.status = "No Data"
            return
        }

        let status = status(slot: slot)

        self.status = "\(status) ago"
        self.statusColor = Color(ColorRamp.color(for: slot.date))

    }

}

struct TimeslotDraverView_Previews: PreviewProvider {

    static func state() -> TimeslotState {
        let state = TimeslotState()
        state.slots = [
            Timeslot(date: Date(), observations: []),
            Timeslot(date: Date().addMinutes(30), observations: [])
        ]

        state.slots[0].color = UIColor.red
        state.slots[1].color = UIColor.blue

        state.selectedIndex = 0

        return state
    }

    static var previews: some View {
        TimeslotDrawerView()
            .environmentObject(state())
    }
}
