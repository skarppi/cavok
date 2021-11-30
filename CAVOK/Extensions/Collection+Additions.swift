//
//  Collection+Additions.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 30.11.2021.
//

import Foundation

extension Collection where Indices.Iterator.Element == Index {

    subscript (safe index: Index?) -> Iterator.Element? {
        if let index = index, indices.contains(index) {
            return self[index]
        }
        return nil
    }
}
