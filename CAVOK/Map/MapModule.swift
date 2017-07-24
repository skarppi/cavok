//
//  MapModule.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 20.01.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

protocol MapModule: class {
    init(delegate: MapDelegate)
    
    func didTapAt(coord: MaplyCoordinate)
    
    func refresh()
    
    func configure(open: Bool)
    
    func render(frame: Int?)
    
    func annotation(object: Any, parentFrame: CGRect) -> UIView?
}
