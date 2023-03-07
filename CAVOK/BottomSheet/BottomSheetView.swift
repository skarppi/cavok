//
//  BottomSheetView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 17.1.2023.
//

import SwiftUI
import Combine

extension View {

    @ViewBuilder
    func bottomSheet<HContent: View, MContent: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder headerContent: @escaping () -> HContent,
        @ViewBuilder mainContent: @escaping () -> MContent
    ) -> BottomSheetView<HContent, MContent, Self> {
        BottomSheetView(
            isPresented: isPresented,
            onDismiss: onDismiss,
            headerContent: headerContent(),
            mainContent: mainContent(),
            view: self
        )
    }
}

extension PresentationDetent {
    static let dynamicHeader = Self.height(-1)

    static let dynamicMain = Self.height(-2)
}

struct BottomSheetView<HContent: View, MContent: View, V: View>: View {
    let isPresented: Binding<Bool>
    let onDismiss: (() -> Void)?

    let headerContent: HContent
    let mainContent: MContent
    let view: V

    internal let conf: BottomSheetConfig = BottomSheetConfig()

    @State var headerSize: CGFloat?

    func toDynamic(_ detent: PresentationDetent) -> PresentationDetent {
        if detent == .dynamicHeader, let headerSize = headerSize {
            print("sheet using dynamic height \(headerSize) with selection \(conf.presentationDetents)")
            return PresentationDetent.height(headerSize)
        }
        return detent
    }

    func toDynamic() -> Set<PresentationDetent> {
        return Set(conf.presentationDetents.map(toDynamic))
    }

    var body: some View {
        view.sheet(isPresented: isPresented, onDismiss: onDismiss) {
            VStack(alignment: .leading) {
                headerContent
                    .padding(.top, 20)
                    .background(GeometryReader { geometry in
                        Color.clear.onAppear {
                            headerSize = geometry.size.height
                        }.onChange(of: geometry.size) { _ in
                            headerSize = geometry.size.height
                        }
                    })

                mainContent
            }
            .padding(.top)
            .background(Material.ultraThinMaterial)
            .presentationDetents(
                toDynamic(),
                selection: Binding(
                    get: {
                        return toDynamic(conf.selection.wrappedValue)
                    },
                    set: { newHeight in
                        if conf.presentationDetents.contains(newHeight) {
                            conf.selection.wrappedValue = newHeight
                        } else {
                            conf.selection.wrappedValue = .dynamicHeader
                        }
                    }
                )
            )
            .presentationDragIndicator(conf.presentationDragIndicator)
            .interactiveDismissDisabled(false)
            .onAppear {
                guard let controller = UIApplication.shared.sceneRootPresentedVC(),
                      let sheet = UIApplication.shared.sheetVC() else {
                    return
                }
                controller.view.backgroundColor = conf.bgColor

                // Determines whether scrolling expands the sheet to a large detent
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false

                sheet.prefersGrabberVisible = false
                sheet.largestUndimmedDetentIdentifier = conf.largestUndimmedDetentIdentifier
                sheet.prefersEdgeAttachedInCompactHeight = true
            }
        }
    }

    func presentationDetents(_ detents: Set<PresentationDetent>) -> BottomSheetView {
        self.conf.presentationDetents = detents
        self.conf.selection = .constant(detents.first!)
        return self
    }

    func presentationDetents(_ detents: Set<PresentationDetent>, selection: Binding<PresentationDetent>) -> BottomSheetView {
        self.conf.presentationDetents = detents
        self.conf.selection = selection
        return self
    }

    func presentationDragIndicator(_ visibility: Visibility) -> BottomSheetView {
        self.conf.presentationDragIndicator = visibility
        return self
    }

    func largestUndimmedDetentIdentifier(_ detentIdentifier: UISheetPresentationController.Detent.Identifier) -> BottomSheetView {
        self.conf.largestUndimmedDetentIdentifier = detentIdentifier
        return self
    }

    func bgColor(_ bgColor: UIColor) -> BottomSheetView {
        self.conf.bgColor = bgColor
        return self
    }

//        .onReceive(toDetent) { detent in
//            guard let sheet = UIApplication.shared.sheetVC() else { return }
//
//            sheet.animateChanges {
//                sheet.selectedDetentIdentifier = detent
//            }
//        }
}

struct BottomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        Text("MOI")
            .bottomSheet(
                isPresented: .constant(true),
                headerContent: {
                    Text("Header")
                },
                mainContent: {
                    Text("Content")
                }
            ).presentationDetents(
                [.dynamicHeader, .large],
                selection: .constant(.dynamicHeader)
            )
    }
}
