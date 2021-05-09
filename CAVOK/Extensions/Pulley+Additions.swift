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
        return self.parent as? PulleyViewController
    }
}

public class PulleySizes {
    var collapsedHeight: CGFloat?
    var partialHeight: CGFloat?
    var fullEnabled: Bool = false

    init(collapsed: CGFloat?, partial: CGFloat?, full: Bool) {
        collapsedHeight = collapsed
        partialHeight = partial
        fullEnabled = full
    }
}

extension PulleyViewController {
    public func setDrawerContent<Content: View>(view: Content, sizes: PulleySizes, animated: Bool = true) {

        let host = PulleyUIHostingController(rootView: view)
        host.sizes = sizes

        setDrawerContentViewController(controller: host, animated: animated)
    }
}

class PulleyUIHostingController<Content>: UIHostingController<Content>,
                                          PulleyDrawerViewControllerDelegate where Content: View {

    var sizes: PulleySizes! = nil

    func supportedDrawerPositions() -> [PulleyPosition] {

        return [sizes.collapsedHeight != nil ? PulleyPosition.collapsed : nil,
                sizes.partialHeight != nil ?  PulleyPosition.partiallyRevealed : nil,
                sizes.fullEnabled ? PulleyPosition.open : nil].compactMap {$0}
    }

    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return sizes.collapsedHeight! + (pulley.currentDisplayMode == .drawer ? bottomSafeArea : 0)
    }

    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        let maxAvailableHeight = UIApplication.shared.windows.first {$0.isKeyWindow}!.frame.height
        guard (sizes.partialHeight ?? 0) > 0 else {
            return maxAvailableHeight / 2
        }

        let height = sizes.partialHeight!
        if pulley.currentDisplayMode == .drawer {
            return min(maxAvailableHeight - bottomSafeArea - pulley.drawerTopInset, height + bottomSafeArea)
        } else {
            return min(maxAvailableHeight - pulley.drawerTopInset * 2, height)
        }
    }
}
