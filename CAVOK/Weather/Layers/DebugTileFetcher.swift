//
//  DebugTileFetcher.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 27.05.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class DebugTileFetcher: WeatherTileFetcher {

    let debugColors: [Int] = [0x86812D, 0x5EB9C9, 0x2A7E3E, 0x4F256F, 0xD89CDE, 0x773B28, 0x333D99, 0x862D52, 0xC2C653, 0xB8583D]

    var loader: MaplyQuadImageFrameLoader?

//    init(mapView: WhirlyGlobeViewController, presentation: ObservationPresentation, region: WeatherRegion?) {
//        super.init(mapView, presentation, region)
//    }

    class func save(_ tileID: MaplyTileID, frame: Int, data: Data?) {
        if let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true).first {
            let path = "\(dir)/\(tileID.level)x\(tileID.x)x\(tileID.y)-\(frame).png"
            try? data?.write(to: URL(fileURLWithPath: path), options: [])
        }
    }

    class func save(_ tileID: MaplyTileID, frame: Int, image: CGImage) {
        save(tileID, frame: frame, data: UIImage(cgImage: image).pngData())
    }

    override func data(forTile fetchInfo: Any, tileID: MaplyTileID) -> Any? {
//    func fetchTile(layer: MaplyQuadImageLoader, tileID: MaplyTileID, frame:Int32) -> Data? {

        let info = fetchInfo as? WeatherTileFetchInfo

        let bbox = loader?.geoBounds(forTile: tileID)

        // print("Fetched frame \(fetchInfo) tile: \(tileID.level): (\(tileID.x),\(tileID.y)) ll = \(bbox?.ll.deg.x ?? 0) x \(bbox?.ll.deg.y ?? 0) ur = \(bbox?.ur.deg.x ?? 0) x \(bbox?.ur.deg.y ?? 0)")

        let w = CGFloat(tileSize())

        let size = CGSize(width: w, height: w)
        UIGraphicsBeginImageContext(size)

        // Draw into the image context
        let hexColor = debugColors[Int(tileID.level) % debugColors.count]
        let red = CGFloat(((hexColor) >> 16) & 0xFF)/255.0
        let green = CGFloat(((hexColor) >> 8) & 0xFF)/255.0
        let blue = CGFloat(((hexColor) >> 0) & 0xFF)/255.0

        let valid: CGFloat = tileID.validTile(config: config) ? 0.5 : 0.1

        let backColor = UIColor(red: 0, green: 0, blue: 0, alpha: valid)

        let fillColor = UIColor(red: red, green: green, blue: blue, alpha: valid)
        let ctx = UIGraphicsGetCurrentContext()

        // Draw a rectangle around the edges for testing
        backColor.setFill()
        ctx?.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))

        backColor.setStroke()
        ctx?.stroke(CGRect(x: 0, y: 0, width: size.width-1, height: size.height-1))

        fillColor.setStroke()
        fillColor.setFill()
        ctx?.setTextDrawingMode(CGTextDrawingMode.fill)
        let textStr = "\(tileID.level) \(info?.frame ?? 0): (\(tileID.x),\(tileID.y)) \(valid) = (\(bbox?.ll.deg.x ?? 0),\(bbox?.ll.deg.y ?? 0))"
        textStr.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height), withAttributes: nil)

        // Grab the image and shut things down
        let retImage = UIGraphicsGetImageFromCurrentImageContext()
        let imgData = retImage!.pngData()
        UIGraphicsEndImageContext()

        return imgData
    }
}
