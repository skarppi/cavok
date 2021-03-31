//
//  PullToRefresh.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 27.3.2021.

import Foundation
import SwiftUI
import CoreHaptics

// copied from https://www.jakelanders.com/swiftui/swiftui-pull-to-refresh/
struct PullToRefreshView<Content>: View where Content : View {
    @Environment(\.colorScheme) var colorScheme
    // passed content view
    let content: () -> Content

    // action to be performed when the user scrolls
    var action: () -> Void

    // whether loading is occuring or not
    @Binding var isLoading: Bool

    // init all variables
    init?(action: (() -> Void)? = {}, isLoading: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.action = action!
        self._isLoading = isLoading
        self.content = content
    }

    // colors for the background of the scroll indicator
    private let darkColor: Color = Color(red: 40 / 255, green: 40 / 255, blue: 40 / 255)
    private let lightColor: Color = Color(red: 240 / 255, green: 240 / 255, blue: 245 / 255)

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
                        if !isLoading {
                            content()
                                // prevent bounce up
                                .offset(y: scrollOffset < 0 ? -scrollOffset : 0)
                                .opacity(1 - arrowAngle / 180)
                        }
                    }
                    .offset(y: isLoading ? 40 : 0)  // offset the content to allow the progress indicator to show when loading
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
                    // keep show loading indicator
                    // spring animation is very important
                    withAnimation(.spring()) { isLoading = true }
                    hasPulled = false
                }
            }
        }
    }

    // view that is shown when the user scrolls
    private var scrollableContent: some View {
        ZStack(alignment: .top) {
            colorScheme == .light ? lightColor : darkColor
            Group {
                if arrowAngle > 180 || hasPulled || isLoading {
                    ProgressView()
                        .onAppear {
                            // indicate the user has pulled all the way
                            withAnimation { hasPulled = true }
                            // complete the action supplied
                            action()
                            // let user know they have pulled enough with a haptic
                            haptic.impactOccurred()
                        }
                } else {
                    // show an arrow that lets the user know they can drag the view
                    Image(systemName: "arrow.down")
                        .rotationEffect(Angle(degrees: arrowAngle < 180 ? arrowAngle : 180))
                        .opacity(arrowAngle > 45 ? (arrowAngle - 45) / 180: 0)
                }
            }
            .frame(height: 40)
            .font(.system(size: 18, weight: .bold))
        }
        .frame(height: 50 + (scrollOffset > 0 ? scrollOffset : 0)) // only allow height to increase if the user scrolls down
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
