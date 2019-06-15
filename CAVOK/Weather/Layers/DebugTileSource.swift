//
//  DebugTileSource.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 27.05.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class DebugTileSource : WeatherTileSource {
    
    let debugColors: [Int] = [0x86812D, 0x5EB9C9, 0x2A7E3E, 0x4F256F, 0xD89CDE, 0x773B28, 0x333D99, 0x862D52, 0xC2C653, 0xB8583D]
    
    class func save(_ tileID: MaplyTileID, data: Data?) {
        if let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true).first {
            let path = "\(dir)/\(tileID.level)x\(tileID.x)x\(tileID.y).png"
            try? data?.write(to: URL(fileURLWithPath: path), options: [])
        }
    }
    
    class func save(_ tileID: MaplyTileID, image: CGImage) {
        save(tileID, data: UIImage(cgImage: image).pngData())
    }
    
    override func fetchTile(layer: MaplyQuadImageTilesLayer, tileID: MaplyTileID, frame:Int32) -> Data? {
        let bbox = layer.geoBounds(forTile: tileID)
        
        print("Fetched frame \(frame) tile: \(tileID.level): (\(tileID.x),\(tileID.y)) ll = \(bbox.ll.deg.x) x \(bbox.ll.deg.y) ur = \(bbox.ur.deg.x) x \(bbox.ur.deg.y)")
        
        let w = CGFloat(tileSize())
        
        let size = CGSize(width: w, height: w)
        UIGraphicsBeginImageContext(size)
        
        // Draw into the image context
        let hexColor = debugColors[Int(tileID.level) % debugColors.count]
        let red = CGFloat(((hexColor) >> 16) & 0xFF)/255.0
        let green = CGFloat(((hexColor) >> 8) & 0xFF)/255.0
        let blue = CGFloat(((hexColor) >> 0) & 0xFF)/255.0
        let backColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        let fillColor = UIColor(red: red, green: green, blue: blue, alpha: 0.5)
        let ctx = UIGraphicsGetCurrentContext()
        
        // Draw a rectangle around the edges for testing
        backColor.setFill()
        ctx?.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        backColor.setStroke()
        ctx?.stroke(CGRect(x: 0, y: 0, width: size.width-1, height: size.height-1))
        
        fillColor.setStroke()
        fillColor.setFill()
        ctx?.setTextDrawingMode(CGTextDrawingMode.fill)
        let textStr = "\(tileID.level): (\(tileID.x),\(tileID.y)) = (\(bbox.ll.deg.x),\(bbox.ur.deg.x))"
        textStr.draw(in: CGRect(x: 0,y: 0,width: size.width,height: size.height), withAttributes:nil)
        
        // Grab the image and shut things down
        let retImage = UIGraphicsGetImageFromCurrentImageContext()
        let imgData = retImage!.pngData()
        UIGraphicsEndImageContext()
        
        return imgData;
    }
}
