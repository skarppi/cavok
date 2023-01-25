//
//  BottomSheetConfig.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 18.1.2023.
//

import SwiftUI

internal class BottomSheetConfig {
    var presentationDetents: Set<PresentationDetent> = [.large]
    var selection: Binding<PresentationDetent> = .constant(.large)
    var presentationDragIndicator: Visibility = .visible
    var largestUndimmedDetentIdentifier: UISheetPresentationController.Detent.Identifier = .large
    var bgColor: UIColor? = UIColor.secondarySystemBackground
}
