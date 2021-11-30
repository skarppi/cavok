//
//  PullToRefresh.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 27.3.2021.

import Foundation
import SwiftUI
import CoreHaptics

// copied from https://www.jakelanders.com/swiftui/swiftui-pull-to-refresh/
struct PullToRefreshView<Content>: View where Content: View {
    @Environment(\.colorScheme) var colorScheme
    // passed content view
    let content: () -> Content

    @Environment(\.refresh) private var refresh

    // message shown whether loading is occuring or not
    @Binding var loadingMessage: String?

    // init all variables
    init?(loadingMessage: Binding<String?>, @ViewBuilder content: @escaping () -> Content) {
        self._loadingMessage = loadingMessage
        self.content = content
    }

    // haptic feedback for when user has pulled enough
    private let haptic = UIImpactFeedbackGenerator(style: .heavy)

    // for reading how much the user has scrolled
    @State private var scrollOffset: CGFloat = 0
    // angle the arrow turns
    @State private var arrowAngle: Double = 0
    // wether the user has pulled enough or not
    @State private var hasPulled: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            // scroll indicator
            scrollableContent
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
                if value > 10 {
                    arrowAngle = Double((value - 10) * 10)
                }
                // indicate the user has pulled all the way
                if arrowAngle > 180 {
                    withAnimation { hasPulled = true }
                }
                // start the loading when the user releases the screen
                if arrowAngle < 180 && hasPulled {
                    // complete the action supplied
                    if let refresh = refresh {
                        Task {
                            await refresh()
                            hasPulled = false
                        }
                    }

                    // let user know they have pulled enough with a haptic
                    haptic.impactOccurred()
                }
            }
        }
    }

    // view that is shown when the user scrolls
    private var scrollableContent: some View {
        Group {
            if hasPulled || loadingMessage != nil {
                ProgressView(loadingMessage ?? "")
                    .frame(height: 80)
            } else {
                // show an arrow that lets the user know they can drag the view
                Image(systemName: "arrow.down")
                    .rotationEffect(Angle(degrees: arrowAngle < 180 ? arrowAngle : 180))
                    .opacity(arrowAngle > 15 ? (arrowAngle - 45) / 180: 0)
                    .frame(height: 40)
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
