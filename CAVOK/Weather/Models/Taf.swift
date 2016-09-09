//
//  Taf.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 05.07.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

public class Taf: Observation {
    
    override public func parse(raw: String) {
        super.parse(raw: raw)
        
        let parser = Tokenizer(raw: self.raw)
        
        // TAF
        parser.next()
        
        if let type = parser.peek()  {
            if type.contains(["COR", "AMD"]) {
                self.type = type
                parser.next()
            }
        }
        
        // identifier
        self.identifier = parser.pop()!
        
        if let time = parser.pop() {
            self.datetime = parseDate(value: time)
        }
        
        // validity
        parser.next()
        
        if let wind = parseWind(value: parser.peek()) {
            self.wind = wind
            parser.next()
        } else {
            self.wind = WindData()
        }
        
        if parseWindVariability(value: parser.peek()) {
            self.windVariability = parser.pop()
        }
        
        if let vis = parseVisibility(value: parser.peek()) {
            self.visibility.value = vis
            
            parser.next()
        } else {
            self.visibility.value = nil
        }
        
        self.weather = parser.loop { current in
            return isSkyCondition(field: current)
        }.joined(separator: " ")
        
        self.clouds = parser.loop { current in
            return !isSkyCondition(field: current)
        }.joined(separator: " ")
        
        self.cloudHeight.value = getCombinedCloudHeight()

        self.supplements = parser.all().joined(separator: " ")
        
        // post-process
        
        if self.visibility.value == nil && isCavok() {
            self.visibility.value = 10000
        }
        
        self.condition = self.parseCondition().rawValue
    }
    
}
