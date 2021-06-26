//
//  MapViewController.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 04.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import UIKit
import SwiftUI
import CoreLocation
import PromiseKit
import Pulley

class MapViewController: UIViewController, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var moduleType: UISegmentedControl!

    @IBOutlet var moduleTypeLeftConstraint: NSLayoutConstraint!

    @IBOutlet weak var buttonView: UIView!

    @IBOutlet weak var legendView: LegendView!

    internal var mapView: WhirlyGlobeViewController!

    fileprivate var module: MapModule!

    


    private var backgroundLoader: MaplyQuadImageLoader?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !UIApplication.withSafeAreas {
            // add some margin between top of the screen and segmented control
            additionalSafeAreaInsets.top = 10
        }

        drawerDisplayModeDidChange(drawer: pulley)
    }

    @IBAction func resetRegion() {
        buttonView.isHidden = true
        legendView.isHidden = true

        animateModuleType(show: false)
        module.configure(open: true)
    }

    fileprivate func animateModuleType(show: Bool) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.moduleType.alpha = (show ? 1 : 0)
        }, completion: { _ in
            self.moduleType.isHidden = self.moduleType.alpha == 0
        })
    }
}

extension MapViewController: PulleyPrimaryContentControllerDelegate {

    func drawerDisplayModeDidChange(drawer: PulleyViewController) {

        if let window = UIApplication.shared.windows.first(where: {$0.isKeyWindow}) {

            if window.safeAreaInsets != .zero {
                // adjust position of the drawer on iPhoneX
                switch window.windowScene?.interfaceOrientation {
                case .landscapeLeft:
                    print("left")
                    // reduce safe area when notch is on the other side
                    drawer.additionalSafeAreaInsets.left = 0 - window.safeAreaInsets.left / 2
                case .landscapeRight:
                    print("right")
                    // decrease the margin to notch
                    drawer.additionalSafeAreaInsets.left = -15
                default:
                    print("default")
                    drawer.additionalSafeAreaInsets.left = 0
                }
            }

            // when pulley is on the left, move segmented control out of the way
            moduleTypeLeftConstraint.constant = drawer.currentDisplayMode == .panel ? pulley.panelWidth + 16*2 : 16
        }
    }
}
