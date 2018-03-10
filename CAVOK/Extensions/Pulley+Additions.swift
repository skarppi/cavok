//
//  Pulley+Additions.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 10.03.2018.
//  Copyright © 2018 Juho Kolehmainen. All rights reserved.
//

import Foundation
import Pulley

extension UIViewController {
    
    var pulley: PulleyViewController! {
        get {
            return self.parent as! PulleyViewController
        }
    }
}
