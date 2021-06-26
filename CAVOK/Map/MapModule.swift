//
//  MapModule.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 20.01.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import PromiseKit

protocol MapModule: AnyObject {
    init(delegate: MapApi)

    func cleanup()

    func configure(open: Bool)

    func render(frame: Int)
}
