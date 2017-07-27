//
//  Taf.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 05.07.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

public class Taf: Observation {
    
    public dynamic var from: Date = Date()
    public dynamic var to: Date = Date()
    
    override public func parse(raw: String) {
        super.parse(raw: raw)
        
        let parser = Tokenizer(raw: self.raw)
        
        if parser.peek() == "TAF" {
            parser.next()
        }
        
        if let type = parser.peek()  {
            if type.contains(["COR", "AMD"]) {
                self.type = type
                parser.next()
            }
        }
        
        // identifier
        self.identifier = parser.pop()!
        
        let time = parseDate(value: parser.peek())
        if let time = time {
            self.datetime = time
            parser.next()
        }
        
        // validity start and end
        if let (from,to) = parse(validity: parser.pop()) {
            if time == nil {
                self.datetime = from
            }
            self.from = from
            self.to = to
        }
        
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
    
    private func parse(validity: String?) -> (Date, Date)? {
        if let validity = validity {
            let components = validity.components(separatedBy: "/").map { component -> Date in
                if component.hasSuffix("24") {
                    let day = component.subString(0, length: 2)
                    return self.parseDate(value: "\(day)0000Z", dayOffset: 1)!
                }
                return self.parseDate(value: "\(component)00Z")!
            }
            return (components[0], components[1])
        }
        return nil
        
    }

}
