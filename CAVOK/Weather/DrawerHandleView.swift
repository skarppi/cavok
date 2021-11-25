//
//  DrawerHandleView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 2.5.2021.
//

import SwiftUI

enum DrawerPosition {
    case top, bottom
}

struct DrawerHandleView: View {

    var position: DrawerPosition

    static func height() -> CGFloat {
//        if Pulley.shared.currentDisplayMode == .drawer {
            return 0
//        } else {
//            return DrawerHandleView.totalHeight
//        }
    }

    private static let totalHeight: CGFloat = 15

    var body: some View {
        Group {
            if position == .top {//&& orientation == .drawer || position == .bottom && orientation != .drawer {
                Capsule()
                    .fill(Color.secondary)
                    .frame(width: 36, height: 5)
                    .padding(.top, 5)
                    .padding(.bottom, 7)
            }
        }.frame(maxWidth: .infinity,
                minHeight: DrawerHandleView.totalHeight,
                maxHeight: DrawerHandleView.totalHeight,
                alignment: .center)
//        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
//            orientation = Pulley.shared.currentDisplayMode
//        }.onAppear {
//            orientation = Pulley.shared.currentDisplayMode
//        }
    }
}

struct DrawerHandleView_Previews: PreviewProvider {
    static var previews: some View {
        DrawerHandleView(position: .top)
    }
}
