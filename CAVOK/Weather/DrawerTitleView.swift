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
        HStack {
            Text(title ?? "-")
                .font(.title)
                .bold()
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button(action: action) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .font(.title)
        }
    }
}

struct DrawerTitleView_Previews: PreviewProvider {
    static var previews: some View {
        DrawerTitleView(title: "Title is too long to fit into one row even when landscape or is it") {
        }
    }
}
