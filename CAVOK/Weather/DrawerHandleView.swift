//
//  DrawerHandleView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 2.5.2021.
//

import SwiftUI

struct DrawerHandleView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(Color.secondary)
            .frame(width: 50, height: 5)
            .padding(5)
    }
}

struct DrawerHandleView_Previews: PreviewProvider {
    static var previews: some View {
        DrawerHandleView()
    }
}
