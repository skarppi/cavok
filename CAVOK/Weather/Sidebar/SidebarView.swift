//
//  SidebarView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 28.3.2023.
//

import SwiftUI

struct SidebarView: View {
    var body: some View {
        TimelineView(.everyMinute) { timeline in
            List {
                FavoriteObservationsView(now: timeline.date)
                NearbyObservationsView(now: timeline.date)
            }.scrollContentBackground(.hidden)
        }
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
            .environmentObject(NavigationManager())
    }
}
