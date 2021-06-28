//
//  DrawerTitleView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 31.3.2021.
//

import SwiftUI

struct DrawerTitleView: View {
    var title: String?
    var action: (() -> Void)

    var body: some View {
        VStack {
            DrawerHandleView(position: .top)

            HStack {
                Text(title ?? "-").font(.system(.title))
                Spacer()
                Button(action: self.action) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding()
                }
            }
        }
    }
}

struct DrawerTitleView_Previews: PreviewProvider {
    static var previews: some View {
        DrawerTitleView(title: "Title") {
        }
    }
}
