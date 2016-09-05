//
//  ViewController.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 04.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private var mapView: WhirlyGlobeViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create an empty globe and add it to the view
        mapView = WhirlyGlobeViewController()
        
        self.view.addSubview(mapView.view)
        mapView.view.frame = self.view.bounds
        addChildViewController(mapView)
        
        mapView.keepNorthUp = true
        mapView.frameInterval = 2 // 30fps
        mapView.threadPerLayer = true
        mapView.autoMoveToTap = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

