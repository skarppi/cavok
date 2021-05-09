//
//  Maply+Additions.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 07.09.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

extension MaplyBoundingBox {
    func inside(_ inner: MaplyCoordinate) -> Bool {
        return ((self.ll.x < inner.x) && (self.ll.y < inner.y) && (inner.x < self.ur.x) && (inner.y < self.ur.y))
    }

    func tiles(zoom: Int32) -> (ll: MaplyTileID, ur: MaplyTileID) {
        let ll = self.ll.tile(offsetX: 0, offsetY: 1, zoom: zoom)
        let ur = self.ur.tile(offsetX: 1, offsetY: 0, zoom: zoom)

        return (ll: ll, ur: ur)
    }

    // local coordinate in radians to 0 - 1
    func normalizeX(_ rad: Float) -> Float {
        let scaled = (rad - ll.x) / (ur.x - ll.x)
        assert(0 <= scaled && scaled <= 1.0)
        return scaled
    }

    // local coordinate in radians to 0 - 1
    func normalizeY(_ rad: Float) -> Float {
        let scaled = (rad - ll.y) / (ur.y - ll.y)
        assert(0 <= scaled && scaled <= 1.0)
        return scaled
    }

    func normalize(_ coord: MaplyCoordinate) -> (x: Float, y: Float) {
        let lon = normalizeX(coord.x)
        let lat = normalizeY(coord.y)
        return (x: lon, y: lat)
    }
}

extension MaplyCoordinate {
    static let kRadiansToDegrees: Float = 180.0 / .pi
    static let kDegreesToRadians: Float = .pi / 180.0
    static let earthRadius = Float(6371.01) // Earth's radius in Kilometers

    var deg: MaplyCoordinate {
        return MaplyCoordinate(x: self.x * MaplyCoordinate.kRadiansToDegrees,
                               y: self.y * MaplyCoordinate.kRadiansToDegrees)
    }

    func tile(offsetX: Int32, offsetY: Int32, zoom: Int32) -> MaplyTileID {
        let scale = pow(2.0, Double(zoom))

        let lon = Double(self.x * MaplyCoordinate.kRadiansToDegrees)
        let x = Int32(floor((lon + 180.0) / 360.0 * scale))

        let lat = Double(self.y)
        let y  = Int32(floor((1.0 - log( tan(lat) + 1.0 / cos(lat)) / Double.pi) / 2.0 * scale))

        return MaplyTileID(x: x + offsetX, y: y + offsetY, level: zoom)
    }

    // finds a new location on a straight line towards a second location, given distance in kilometers.
    func locationAt(kilometers: Float, direction: Float) -> MaplyCoordinate {
        let lat1 = Float.pi/2 - self.y
        let dRad = direction * MaplyCoordinate.kDegreesToRadians

        let numC = kilometers / MaplyCoordinate.earthRadius

        let numA = acosf(cosf(numC)*cosf(lat1) + sinf(lat1)*sinf(numC)*cosf(dRad))
        let dLon = asin(sin(numC)*sin(dRad)/sin(numA))

        return MaplyCoordinateMake(dLon + self.x, Float.pi/2 - numA)
    }
}

extension MaplyTileID {

    private static func coord(x: Int32, y: Int32, z: Int32) -> MaplyCoordinate {
        let scale = pow(2, Double(z))

        let lon = Double(x) / scale * 360.0 - 180.0

        let n = Double.pi - 2 * Double.pi * Double(y) / scale
        let lat = 180 / Double.pi * atan(0.5*(exp(n) - exp(-n)))

        return MaplyCoordinateMakeWithDegrees(Float(lon), Float(lat))
    }

    var coordinate: MaplyCoordinate {
        return MaplyTileID.coord(x: self.x, y: self.y, z: self.level)
    }

    var bbox: MaplyBoundingBox {
        return MaplyBoundingBox(
            ll: MaplyTileID.coord(x: self.x, y: self.y + 1, z: self.level),
            ur: MaplyTileID.coord(x: self.x + 1, y: self.y, z: self.level)
        )
    }

    var bboxFlip: MaplyBoundingBox {
        let yFlip = (1<<self.level)-self.y-1
        return MaplyBoundingBox(
            ll: MaplyTileID.coord(x: self.x, y: yFlip + 1, z: self.level),
            ur: MaplyTileID.coord(x: self.x + 1, y: yFlip, z: self.level)
        )
    }

    /** @brief Check if we should even try to load a given tile.
     @details Tile pyramids can be sparse.  If you know where your pyramid is sparse,
     you can short circuit the fetch and simply return false here.
     @details If this method isn't filled in, everything defaults to true.
     @details tileID The tile we're asking about.
     @details bbox The bounding box of the tile we're asking about, for convenience.
     @return True if the tile is loadable, false if not.
     */
    func validTile(config: WeatherConfig) -> Bool {
        let y = (1<<self.level)-self.y-1 // flip
        let x = self.x

        let tile = config.tiles[Int(self.level)]

        if x >= tile.ur.x || (x + 1) <= tile.ll.x || (y + 1) <= tile.ur.y ||  y >= tile.ll.y {
            return false
        }

        return true
    }
}

extension MaplySphericalMercator {
    func geo(toLocalBox bbox: MaplyBoundingBox) -> MaplyBoundingBox {
        return MaplyBoundingBox(
            ll: geo(toLocal: bbox.ll),
            ur: geo(toLocal: bbox.ur)
        )
    }
}
