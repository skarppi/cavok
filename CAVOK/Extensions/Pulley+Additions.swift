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
        return pulleySizes.collapsedHeight + (pulley.displayMode == .drawer ? bottomSafeArea : 0)
    }

    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        let maxAvailableHeight = UIApplication.shared.windows.first {$0.isKeyWindow}!.frame.height
        guard pulleySizes.fullHeight > 0 else {
            return maxAvailableHeight
        }
    
        let height = pulleySizes.fullHeight
        if pulley.displayMode == .drawer {
            return min(maxAvailableHeight - bottomSafeArea - pulley.drawerTopInset, height + bottomSafeArea)
        } else {
            return min(maxAvailableHeight - pulley.drawerTopInset * 2, height)
        }
    }
}
