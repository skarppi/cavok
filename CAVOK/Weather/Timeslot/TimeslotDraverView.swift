//
//  TimeslotView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 27.3.2021.
//

import SwiftUI

struct TimeslotDrawerView: View {
    var refresh: (() -> Void)

    @EnvironmentObject var state: TimeslotState

    @GestureState var cursor = CGPoint.zero

    var body: some View {
        PullToRefreshView(action: refreshAction, isLoading: $state.isLoading) {
            DrawerHandleView()

            VStack(alignment: .leading) {
                Text(state.status)
                    .font(.body)
                    .foregroundColor(state.statusColor)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                timeline
            }
            .padding(.horizontal)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .updating($cursor) { (value, state, _) in
                        state = value.location
                    })
        }
    }

    private var timeline: some View {
        ZStack {
            HStack(spacing: 0) {
                ForEach(Array(state.slots.enumerated()), id: \.element) { (index, slot) in
                    Text(slot.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(EdgeInsets(top: 10, leading: 3, bottom: 10, trailing: 3))
                        .background(
                            Rectangle()
                                .fill(Color(slot.color).opacity(0.4))
                        )
                        .border(state.selectedIndex == index ?  Color.black : Color.clear)
                        .background(self.rectReader(index: index))
                }
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

    private func refreshAction() {
        //        setControls(hidden: true)
        state.startSpinning()
        state.refreshRequested.send()
    }
}

struct TimeslotDraverView_Previews: PreviewProvider {

    static func state() -> TimeslotState {
        let state = TimeslotState()
        state.slots = [
            Timeslot(date: Date(), title: "10:30"),
            Timeslot(date: Date(), title: "11:30")
        ]

        state.selectedIndex = 0
        return state
    }

    static var previews: some View {
        TimeslotDrawerView(refresh: {
        })
        .environmentObject(state())
    }
}
