//
//  UIView+Additions.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 17.06.2017.
//  Copyright © 2017 Juho Kolehmainen. All rights reserved.
//

import SwiftUI
import Combine

extension UIApplication {
    func sceneRootPresentedVC() -> UIViewController? {
        guard let windows = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        return windows.windows.first?.rootViewController?.presentedViewController
    }

    func sheetVC() -> UISheetPresentationController? {
        return sceneRootPresentedVC()?.presentationController as? UISheetPresentationController
    }
}

extension View {
}

extension View {
    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    func phoneOnlyStackNavigationView() -> some View {
        if Self.isPhone {
            return AnyView(self.navigationViewStyle(StackNavigationViewStyle()))
        } else {
            return AnyView(self)
        }
    }
}

public extension EnvironmentValues {
    var isPreview: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        return false
        #endif
    }
}
