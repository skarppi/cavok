//
//  LinkEditView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 17.5.2021.
//

import SwiftUI

struct LinkEditView: View {
    @Binding var link: Link

    var body: some View {
        Form {
            Section(header: Text("Link Details")) {
                TextField("Title", text: $link.title)
                TextField("Link", text: $link.url)
                TextField("Block CSS elements on the page", text: $link.blockElements, axis: .vertical)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 100, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .scrollContentBackground(.hidden)
        .background(.thinMaterial)
    }
}

struct LinkEditView_Previews: PreviewProvider {
    static var previews: some View {
        let link = Link(title: "Title", url: "http://", blockElements: "html")
        LinkEditView(link: .constant(link))
    }
}
