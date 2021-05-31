//
//  Links.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 03.09.2017.
//  Copyright © 2017 Juho Kolehmainen. All rights reserved.
//

import Foundation

struct Link: Hashable, Identifiable {
    var id = UUID()
    var title: String
    var url: String
    var blockElements: String

    func buildURL() -> URL? {
        if url.contains("{lat}") || url.contains("{lon") {
            if let deg = LastLocation.load()?.deg {
                let lat = String(deg.y) + (deg.y > 0 ? "N" : "S")
                let lon = String(deg.x) + (deg.x > 0 ? "E" : "W")

                return URL(string: url.replace("{lat}", with: lat).replace("{lon}", with: lon))
            } else {
                return nil
            }
        } else {
            return URL(string: url)
        }
    }
}

class Links {

    class func load() -> [Link] {
        if let links = UserDefaults.standard.array(forKey: "links") as? [[String: String]] {
            return links.compactMap { link in
                guard let title = link["title"], let url = link["url"] else {
                    return nil
                }
                return Link(title: title, url: url, blockElements: link["blockElements"] ?? "")
            }
        } else {
            return []
        }
    }

    class func save(_ links: [Link]) -> Bool {
        print("Saving links \(links)")

        let serialized = links.map { link in
            return ["title": link.title, "url": link.url, "blockElements": link.blockElements]
        }

        let defaults = UserDefaults.standard
        defaults.set(serialized, forKey: "links")
        return defaults.synchronize()
    }
}
