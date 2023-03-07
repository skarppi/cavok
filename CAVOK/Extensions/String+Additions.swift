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
        return self.count
    }

    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }

    func contains(_ str: String) -> Bool {
        return self.range(of: str) != nil
    }

    func contains(_ strs: [String]) -> Bool {
        for str in strs where self.range(of: str) != nil {
            return true
        }
        return false
    }

    func replace(_ target: String, with: String) -> String {
        return self.replacingOccurrences(of: target, with: with, options: NSString.CompareOptions.literal, range: nil)
    }

    subscript (i: Int) -> Character {
        let i = index(startIndex, offsetBy: i)
        return self[i]
    }

    subscript (nsr: NSRange) -> String {
        let range = Range(nsr)!
        return self[range]
    }

    subscript (range: Range<Int>) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)

        return String(self[(startIndex ..< endIndex)])
    }

    func subString(_ startIndex: Int, length: Int) -> String {
        let start = self.index(self.startIndex, offsetBy: startIndex)
        let end = self.index(self.startIndex, offsetBy: startIndex + length)
        return String(self[start ..< end])
    }

    func isMatch(_ regex: String, options: NSRegularExpression.Options = []) -> Bool {
        do {
            let exp = try NSRegularExpression(pattern: regex, options: options)
            let matchCount = exp.numberOfMatches(in: self,
                                                 options: [],
                                                 range: NSRange(location: 0, length: self.length))
            return matchCount > 0
        } catch {
            print(error)
            return false
        }
    }

    func getMatch(_ regex: String, options: NSRegularExpression.Options = []) -> NSTextCheckingResult? {
        do {
            let exp = try NSRegularExpression(pattern: regex, options: options)
            return exp.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.length))
        } catch {
            print(error)
            return nil
        }
    }

    func getMatches(_ regex: String, options: NSRegularExpression.Options = []) -> [NSTextCheckingResult] {
        do {
            let exp = try NSRegularExpression(pattern: regex, options: options)
            return exp.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
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
                self.addAttribute(NSAttributedString.Key(rawValue: name), value: value, range: match.range)
            }
        } catch {
            print("Error creating regular expresion: \(error)")
        }
    }
}
