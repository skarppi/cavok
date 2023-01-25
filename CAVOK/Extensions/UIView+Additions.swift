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
    func phoneOnlyStackNavigationView() -> some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
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
