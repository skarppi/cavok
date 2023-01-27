//
//  AdaptiveStack.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 27.1.2023.
//

import SwiftUI

struct AdaptiveStack<Content: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat?
    let content: (_ isLandscape: Bool) -> Content

    @State private var orientation = UIDeviceOrientation.unknown

    init(horizontalAlignment: HorizontalAlignment = .leading,
         verticalAlignment: VerticalAlignment = .center,
         spacing: CGFloat? = nil,
         @ViewBuilder content: @escaping (Bool) -> Content) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        Group {
            if verticalSizeClass == .compact || horizontalSizeClass == .regular {
                HStack(alignment: verticalAlignment, spacing: spacing) {
                    content(true)
                }
            } else {
                VStack(alignment: horizontalAlignment, spacing: spacing) {
                    content(false)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct AdaptiveStack_Previews: PreviewProvider {
    static var previews: some View {
        AdaptiveStack { isLandscape in
            Text("Horizontal when there's lots of space")
            Text("but \(isLandscape ? "land" : "port")")
            Text("Vertical when space is restricted")
        }
    }
}
