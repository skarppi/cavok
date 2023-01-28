//
//  PullToRefresh.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 27.3.2021.

import Foundation
import SwiftUI
import CoreHaptics

struct PullToRefreshView<Content>: View where Content: View {
    // passed content view
    let content: () -> Content

    // message shown whether loading is occuring or not
    @Binding var loadingMessage: String?

    // init all variables
    init?(loadingMessage: Binding<String?>, @ViewBuilder content: @escaping () -> Content) {
        self._loadingMessage = loadingMessage
        self.content = content
    }

    // for reading how much the user has scrolled
    @State private var scrollOffset: CGFloat = 0
    // angle the arrow turns
    @State private var arrowAngle: Double = 0

    var body: some View {
        ZStack(alignment: .top) {
            if loadingMessage != nil {
                ProgressView(loadingMessage ?? "")
                    .frame(height: 80)
            }

            ScrollView {
                ZStack {
                    // for determining scroll position
                    GeometryReader { proxy in
                        let offset = proxy.frame(in: .named("scroll")).minY
                        Color.clear.preference(key: ViewOffsetKey.self, value: offset)
                    }
                    VStack {
                        if loadingMessage == nil {
                            content()
                                // prevent bounce up
                                .offset(y: scrollOffset < 0 ? -scrollOffset : 0)
                                .opacity(1 - arrowAngle / 180)
                        }
                    }
                }

            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ViewOffsetKey.self) { value in
                // get scroll position
                scrollOffset = value
                // set arrow angle for the user
                arrowAngle = Double((value - 10) * 5)
            }
        }
    }
}

// for retrieving scroll amount
struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
