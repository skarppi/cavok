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
            Capsule()
                .fill(Color.secondary)
                .frame(width: 36, height: 5)

            Text(state.status)
                .font(.body)
                .padding(.leading, 15)
                .foregroundColor(
                    state.statusColor.lighter(by: colorScheme == .dark ? 0.4 : 0))
                .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                .background(Color(.secondarySystemFill))
                .cornerRadius(10)

            timeline.gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .updating($cursor) { (value, state, _) in
                        state = value.location
                    })
        }.padding(.top, 4)
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
}

struct TimeslotDraverView_Previews: PreviewProvider {

    static func state() -> TimeslotState {
        let state = TimeslotState()
        state.slots = [
            Timeslot(date: Date(), title: "10:30"),
            Timeslot(date: Date(), title: "11:30")
        ]

        state.slots[0].color = UIColor.red
        state.slots[1].color = UIColor.blue

        state.selectedIndex = 0

        state.statusColor = Color(UIColor.systemRed)
        return state
    }

    static var previews: some View {
        ForEach(ColorScheme.allCases,
                id: \.self,
                content:
                    TimeslotDrawerView()
                        .environmentObject(state())
                        .background(Color(.secondarySystemGroupedBackground))
                        .preferredColorScheme
        )
    }
}
