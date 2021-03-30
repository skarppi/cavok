//
//  Timeslot.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 27/09/2016.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

public struct Timeslot: Hashable {
    let date: Date
    
    let title: String
    
    var color: UIColor = UIColor.clear
    
    init(date: Date, title: String? = nil) {
        self.date = date
        if let title = title {
            self.title = title
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            self.title = formatter.string(from: date)
        }
    }
}
