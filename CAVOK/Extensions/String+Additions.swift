//
//  String+Additions.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 30.10.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

// copied from https://gist.github.com/albertbori/0faf7de867d96eb83591
extension String {
    
    var length: Int {
        return self.characters.count
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    func contains(_ s: String) -> Bool {
        return self.range(of: s) != nil ? true : false
    }
    
    func contains(_ strs: [String]) -> Bool {
        for s in strs {
            if self.range(of: s) != nil {
                return true
            }
        }
        return false
    }
    
    func replace(_ target: String, with: String) -> String {
        return self.replacingOccurrences(of: target, with: with, options: NSString.CompareOptions.literal, range: nil)
    }
    
    subscript (i: Int) -> Character {
        let index = characters.index(startIndex, offsetBy: i)
        return self[index]
    }
    
    subscript (nsr: NSRange) -> String {
        let r = nsr.toRange()!
        return self[r]
    }
    
    subscript (r: Range<Int>) -> String {
        let startIndex = self.characters.index(self.startIndex, offsetBy: r.lowerBound)
        let endIndex = self.characters.index(self.startIndex, offsetBy: r.upperBound)
        
        return self[(startIndex ..< endIndex)]
    }
    
    func subString(_ startIndex: Int, length: Int) -> String {
        let start = self.characters.index(self.startIndex, offsetBy: startIndex)
        let end = self.characters.index(self.startIndex, offsetBy: startIndex + length)
        return self.substring(with: (start ..< end))
    }
    
    func isMatch(_ regex: String, options: NSRegularExpression.Options = []) -> Bool {
        do {
            let exp = try NSRegularExpression(pattern: regex, options: options)
            let matchCount = exp.numberOfMatches(in: self, options: [], range: NSMakeRange(0, self.length))
            return matchCount > 0
        } catch {
            print(error)
            return false
        }
    }
    
    func getMatch(_ regex: String, options: NSRegularExpression.Options = []) -> NSTextCheckingResult? {
        do {
            let exp = try NSRegularExpression(pattern: regex, options: options)
            return exp.firstMatch(in: self, options: [], range: NSMakeRange(0, self.length))
        } catch {
            print(error)
            return nil
        }
    }
    
    func getMatches(_ regex: String, options: NSRegularExpression.Options = []) -> [NSTextCheckingResult] {
        do {
            let exp = try NSRegularExpression(pattern: regex, options: options)
            return exp.matches(in: self, options: [], range: NSMakeRange(0, self.characters.count))
        } catch {
            print(error)
            return []
        }
    }
}

extension NSMutableAttributedString {
    func addAttribute(_ name: String, value: Any, pattern: String) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: self.string.utf16.count)
            for match in regex.matches(in: self.string, options: .withTransparentBounds, range: range) {
                self.addAttribute(name, value: value, range: match.range)
            }
        } catch {
            NSLog("Error creating regular expresion: \(error)")
        }
    }
}
