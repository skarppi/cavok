//
//  MapModule.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 20.01.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import PromiseKit

protocol MapModule: class {
    init(delegate: MapDelegate)
    
    func cleanup()
    
    func didTapAt(coord: MaplyCoordinate)
    
    func refresh() -> Promise<Void>
    
    func configure(open: Bool)
    
    func render(frame: Int)
    
    func details(object: Any, parentFrame: CGRect)
}
