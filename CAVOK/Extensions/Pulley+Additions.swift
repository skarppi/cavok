//
//  Pulley+Additions.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 10.03.2018.
//  Copyright © 2018 Juho Kolehmainen. All rights reserved.
//

import Foundation
import Pulley
import SwiftUI

extension UIViewController {
    
    var pulley: PulleyViewController! {
        get {
            return self.parent as? PulleyViewController
        }
    }
}


extension PulleyViewController {
    public func setDrawerContent<Content: View>(view: Content, sizes: PulleySizes, animated: Bool = true) {

        let host = PulleyUIHostingController(rootView: view)
        host.pulleySizes = sizes
        
        setDrawerContentViewController(controller: host, animated: animated)
    }
}

class PulleyUIHostingController<Content>: UIHostingController<Content>, PulleyDrawerViewControllerDelegate where Content: View {

    var pulleySizes: PulleySizes! = nil

    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.collapsed, .partiallyRevealed]
    }

    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        print("collapsed \(pulleySizes.collapsedHeight)")

        return pulleySizes.collapsedHeight + (pulley.displayMode == .drawer ? bottomSafeArea : 0)
    }

    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {

        print("full \(pulleySizes.fullHeight)")

        let maxAvailableHeight = UIApplication.shared.windows.first {$0.isKeyWindow}!.frame.height
        if pulley.displayMode == .drawer {
            return min(maxAvailableHeight - bottomSafeArea - pulley.drawerTopInset, pulleySizes.fullHeight + bottomSafeArea)
        } else {
            return min(maxAvailableHeight - pulley.drawerTopInset * 2, pulleySizes.fullHeight)
        }
    }
}
