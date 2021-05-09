//
//  Tokenizer.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 25.01.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

// http://kevinvanderlugt.com/creating-queue-using-swift/
class Tokenizer {
    var items: [String] = []

    init(raw: String) {
        self.items = raw.components(separatedBy: " ")
    }

    func next() {
        if items.count > 0 {
            items.remove(at: 0)
        }
    }

    func loop(stopWhen: (String) -> Bool) -> [String] {
        let endIndex = items.firstIndex(where: stopWhen) ?? items.endIndex
        let matching = items.prefix(upTo: endIndex)
        items.removeSubrange(0 ..< endIndex)
        return Array(matching)
    }

    func all() -> [String] {
        let matching = items
        items.removeAll()
        return matching
    }

    func pop() -> String? {
        if items.count > 0 {
            return items.remove(at: 0)
        } else {
            return nil
        }
    }

    func peek() -> String? {
        if items.count > 0 {
            return items[0]
        } else {
            return nil
        }
    }

    func empty() -> Bool {
        return items.count == 0
    }

    subscript(index: Int) -> String? {
        return items[index]
    }
}
