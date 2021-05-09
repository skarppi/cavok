//
//  Links.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 03.09.2017.
//  Copyright © 2017 Juho Kolehmainen. All rights reserved.
//

import Foundation

struct Link {
    var title: String
    var url: String
    var blockElements: String?
}

class Links {

    class func load() -> [Link] {
        if let links = UserDefaults.standard.array(forKey: "links") as? [[String: String]] {
            return links.compactMap { link in
                guard let title = link["title"], let url = link["url"] else {
                    return nil
                }
                return Link(title: title, url: url, blockElements: link["blockElements"])
            }
        } else {
            return []
        }
    }

    class func save(_ links: [Link]) -> Bool {
        print("Saving links \(links)")

        let serialized = links.map { link in
            return ["title": link.title, "url": link.url, "blockElements": link.blockElements ?? ""]
        }

        let defaults = UserDefaults.standard
        defaults.set(serialized, forKey: "links")
        return defaults.synchronize()
    }
}
