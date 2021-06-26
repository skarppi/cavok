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

    private var backgroundLoader: MaplyQuadImageLoader?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !UIApplication.withSafeAreas {
            // add some margin between top of the screen and segmented control
            additionalSafeAreaInsets.top = 10
        }

//        drawerDisplayModeDidChange(drawer: pulley)
    }

    @IBAction func resetRegion() {
        buttonView.isHidden = true
        legendView.isHidden = true

        animateModuleType(show: false)
//        module.configure(open: true)
    }

    fileprivate func animateModuleType(show: Bool) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.moduleType.alpha = (show ? 1 : 0)
        }, completion: { _ in
            self.moduleType.isHidden = self.moduleType.alpha == 0
        })
    }
}
