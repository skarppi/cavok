//
//  MapModule.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 20.01.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

protocol MapModule {
    init(delegate: MapDelegate)
    
    func refreshData() -> Void
}

protocol MapDelegate {
    func setStatus(text: String?, color: UIColor)
    
    func setStatus(error: Error)
    
    func clearComponents(of: NSObject.Type?)
}
