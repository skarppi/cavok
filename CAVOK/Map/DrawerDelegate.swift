//
//  DrawerDelegate.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 01.12.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

public protocol DrawerDelegate {
    func setStatus(text: String?, color: UIColor)
    
    func setStatus(error: Error)
    
    func loaded(frame:Int?, timeslots: [Timeslot], legend: Legend)
}
