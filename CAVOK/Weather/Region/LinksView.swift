//
//  LinksView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 16.5.2021.
//

import SwiftUI

struct LinksView: View {
    @Binding var links: [Link]

    @State var selected: UUID?

    var body: some View {
        NavigationView {
            List {
                ForEach(links, id: \.id) { link in
                    let index = links.firstIndex(where: { lnk in lnk.id == link.id })!
                    NavigationLink(link.title,
                                   destination: LinkEditView(
                                    link: Binding(get: { link },
                                                  set: { newValue in
                                                    links[index] = newValue})),
                                   tag: link.id,
                                   selection: $selected)
                }
                .onMove(perform: moveRow)
                .onDelete(perform: deleteRow)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitle("Web Links", displayMode: .inline)
            .navigationBarItems(
                trailing: HStack {
                    Button(action: addRow) {
                        HStack {
                            Image(systemName: "plus")
                        }
                    }
                    Spacer(minLength: 30)
                    EditButton()
                }
            )
        }
    }

    private func addRow() {
        let link = Link(title: "", url: "", blockElements: "")
        links.append(link)
        selected = link.id
    }

    private func deleteRow(at indexSet: IndexSet) {
        links.remove(atOffsets: indexSet)
    }

    private func moveRow(from source: IndexSet, to destination: Int) {
        links.move(fromOffsets: source, toOffset: destination)
    }
}

struct LinksView_Previews: PreviewProvider {
    static var previews: some View {
        let links = [
            Link(title: "sää",
                 url: "https://ilmailusaa.fi",
                 blockElements: "")
        ]
        LinksView(links: .constant(links))
    }
}
