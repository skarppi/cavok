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
    
    public func setDrawerContent<Content: View>(view: Content, animated: Bool = true) {
        setDrawerContentViewController(controller: UIHostingController(rootView: view), animated: animated)
        
    }
}
