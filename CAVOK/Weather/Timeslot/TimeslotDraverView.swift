//
//  TimeslotView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 27.3.2021.
//

import SwiftUI

// Our observable object class
class TimeslotState: ObservableObject {
    @Published var slots: [Timeslot] = [Timeslot(date: Date(), title: "")]
    
    @Published var selectedIndex = 0
    
    @Published var status = "Loading"
    
    @Published var statusColor = Color.primary
    
    @Published var isLoading = false
    
    func reset(slots: [Timeslot], selected: Int) {
        self.slots = slots
        selectedIndex = selected
        isLoading = false
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
    
    func setStatus(text: String?, color: UIColor = UIColor.red) {
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

struct TimeslotDrawerView: View {
    var refresh: (() -> Void)
        
    @EnvironmentObject var state: TimeslotState
    
    @GestureState var cursor = CGPoint.zero

    var body: some View {
        PullToRefreshView(action: { refreshAction() }, isLoading: $state.isLoading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.secondary)
                .frame(width: 50, height: 5)
                .padding(5)
        
            VStack(alignment: .leading) {
                Text(state.status)
                    .font(.body)
                    .foregroundColor(state.statusColor)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                
                Timeline
            }
            .padding(.horizontal)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .updating($cursor) { (value, state, transaction) in
                        state = value.location
            })
        }
    }
    
    private var Timeline: some View {
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

//        module?.refresh()
//            .catch(Messages.show)
//            .finally(state.stopSpinning)
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
