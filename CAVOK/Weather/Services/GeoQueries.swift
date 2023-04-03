//
//  GeoQueries.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 4.3.2023.
//

import RealmSwift
import CoreLocation
import MapKit

// copied from https://github.com/mhergon/RealmGeoQueries/blob/master/GeoQueries.swift

enum GeoQueriesError: Error {
    case invalidRealm(String)
}

// MARK: - Public extensions
public extension Realm {

    /**
     Find objects inside MKCoordinateRegion. Useful for use in conjunction with MapKit

     - parameter type:         Realm object type
     - parameter region:       Region that fits MapKit view
     - parameter latitudeKey:  Set to use different latitude key in query (default: "lat")
     - parameter longitudeKey: Set to use different longitude key in query (default: "lng")

     - returns: Found objects inside MKCoordinateRegion
     */
    func findInRegion<Element: Object>(type: Element.Type,
                                       region: MKCoordinateRegion,
                                       latitudeKey: KeyPath<Element, Float?>,
                                       longitudeKey: KeyPath<Element, Float?>) throws -> Results<Element> {

        // Query
        return try self
            .objects(type)
            .filterGeoBox(box: region.geoBox, latitudeKey: latitudeKey, longitudeKey: longitudeKey)

    }

    /**
     Find objects inside GeoBox

     - parameter type:         Realm object type
     - parameter box:          GeoBox struct
     - parameter latitudeKey:  Set to use different latitude key in query (default: "lat")
     - parameter longitudeKey: Set to use different longitude key in query (default: "lng")

     - returns: Found objects inside GeoBox
     */
    func findInBox<Element: Object>(type: Element.Type,
                                    box: GeoBox,
                                    latitudeKey: KeyPath<Element, Float?>,
                                    longitudeKey: KeyPath<Element, Float?>) throws -> Results<Element> {

        // Query
        return try self
            .objects(type)
            .filterGeoBox(box: box, latitudeKey: latitudeKey, longitudeKey: longitudeKey)

    }

    typealias DistinctQuery = (by: String, sorted: String, ascending: Bool)

    /**
     Find objects from center and distance radius

     - parameter type:         Realm object type
     - parameter center:       Center coordinate
     - parameter radius:       Radius in meters
     - parameter order:        Sort by distance (optional)
     - parameter latitudeKey:  Set to use different latitude key in query (default: "lat")
     - parameter longitudeKey: Set to use different longitude key in query (default: "lng")
     - parameter latitudeKey:  Set to use different latitude key in query (default: "lat")

     - returns: Found objects inside radius around the center coordinate
     */
    func findNearby<Element: Object>(
        type: Element.Type,
        origin center: CLLocationCoordinate2D,
        radius: Double,
        sortAscending sort: Bool?,
        distinct: DistinctQuery,
        distanceKey: ReferenceWritableKeyPath<Element, Double?>,
        latitudeKey: KeyPath<Element, Float?>,
        longitudeKey: KeyPath<Element, Float?>) throws -> [Element] {

        // Query
        return try self.objects(type)
            .sorted(byKeyPath: distinct.sorted, ascending: distinct.ascending)
            .distinct(by: [distinct.by])
            .filterGeoBox(box: center.geoBox(radius: radius), latitudeKey: latitudeKey, longitudeKey: longitudeKey)
            .filterGeoRadius(center: center,
                             radius: radius,
                             sortAscending: sort,
                             distanceKey: distanceKey,
                             latitudeKey: latitudeKey,
                             longitudeKey: longitudeKey)
    }

}

public extension RealmCollection where Element: Object {

    /**
     Filter results from Realm query using GeoBox

     - parameter box:          GeoBox struct
     - parameter latitudeKey:  Set to use different latitude key in query (default: "lat")
     - parameter longitudeKey: Set to use different longitude key in query (default: "lng")

     - returns: Filtered objects inside GeoBox
     */
    func filterGeoBox(box: GeoBox,
                      latitudeKey: KeyPath<Element, Float?>,
                      longitudeKey: KeyPath<Element, Float?>) throws -> Results<Element> {

        // Realm instance pre-check
        guard realm != nil else {
            throw GeoQueriesError.invalidRealm("RLMRealm instance is needed to call this method")
        }

        return self.where {
            let latitude = $0[dynamicMember: latitudeKey]
            let longitude = $0[dynamicMember: longitudeKey]
            let topLeftPredicate = latitude <= Float(box.topLeft.latitude) && longitude >= Float(box.topLeft.longitude)
            let bottomRightPredicate = latitude >= Float(box.bottomRight.latitude)
                && longitude <= Float(box.bottomRight.longitude)

            return topLeftPredicate && bottomRightPredicate
        }
    }

    /**
     Filter results from center and distance radius

     - parameter center:       Center coordinate
     - parameter radius:       Radius in meters
     - parameter sort:         Sort by distance (optionl)
     - parameter latitudeKey:  Set to use different latitude key in query (default: "lat")
     - parameter longitudeKey: Set to use different longitude key in query (default: "lng")

     - returns: Found objects inside radius around the center coordinate
     */
    func filterGeoRadius(center: CLLocationCoordinate2D,
                         radius: Double,
                         sortAscending sort: Bool?,
                         distanceKey: ReferenceWritableKeyPath<Element, Double?>,
                         latitudeKey: KeyPath<Element, Float?>,
                         longitudeKey: KeyPath<Element, Float?>) throws -> [Element] {

        // Realm instance pre-check
        guard realm != nil else {
            throw GeoQueriesError.invalidRealm("RLMRealm instance is needed to call this method")
        }

        // Get box
        let inBox = try filterGeoBox(box: center.geoBox(radius: radius),
                                     latitudeKey: latitudeKey,
                                     longitudeKey: longitudeKey)

        // add distance
        let withDistance = inBox.addDistance(center: center, distanceKey: distanceKey, latitudeKey: latitudeKey, longitudeKey: longitudeKey)

        // Inside radius
        let insideRadius = withDistance.filter { obj -> Bool in
            if let distance = obj[keyPath: distanceKey] {
                return distance <= radius
            }
            return false
        }

        // Sort results
        guard let ascending = sort else { return insideRadius }

        return insideRadius.sort(ascending: ascending, distanceKey: distanceKey)

    }

    /// Sort by distance
    ///
    /// - Parameters:
    ///   - center: Center coordinate
    ///   - ascending: Ascendig or descending
    ///   - latitudeKey: Set to use different latitude key in query (default: "lat")
    ///   - longitudeKey: Set to use different longitude key in query (default: "lng")
    /// - Returns: Sorted objects
    func sortByDistance(center: CLLocationCoordinate2D,
                        ascending: Bool,
                        distanceKey: ReferenceWritableKeyPath<Element, Double?>,
                        latitudeKey: KeyPath<Element, Float?>,
                        longitudeKey: KeyPath<Element, Float?>) -> [Element] {

        return self
            .addDistance(center: center, distanceKey: distanceKey, latitudeKey: latitudeKey, longitudeKey: longitudeKey)
            .sort(ascending: ascending, distanceKey: distanceKey)
    }

}

// MARK: - Public core extensions
/// GeoBox struct. Set top-left and bottom-right coordinate to create a box
public struct GeoBox {

    public var topLeft: CLLocationCoordinate2D
    public var bottomRight: CLLocationCoordinate2D

    public init(topLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D) {
        self.topLeft = topLeft
        self.bottomRight = bottomRight
    }

}

public extension CLLocationCoordinate2D {

    /**
     Accessory function to convert CLLocationCoordinate2D to GeoBox

     - parameter radius: Radius in meters

     - returns: GeoBox struct
     */
    func geoBox(radius: Double) -> GeoBox {
        return MKCoordinateRegion(center: self,
                                  latitudinalMeters: radius * 2.0,
                                  longitudinalMeters: radius * 2.0).geoBox
    }

}

public extension MKCoordinateRegion {

    /// Accessory function to convert MKCoordinateRegion to GeoBox
    var geoBox: GeoBox {

        let maxLat = self.center.latitude + (self.span.latitudeDelta / 2.0)
        let minLat = self.center.latitude - (self.span.latitudeDelta / 2.0)
        let maxLng = self.center.longitude + (self.span.longitudeDelta / 2.0)
        let minLng = self.center.longitude - (self.span.longitudeDelta / 2.0)

        return GeoBox(
            topLeft: CLLocationCoordinate2D(latitude: maxLat, longitude: minLng),
            bottomRight: CLLocationCoordinate2D(latitude: minLat, longitude: maxLng)
        )

    }

}

private extension Array where Element: Object {
    /**
     Sorting function

     - parameter ascending: Ascending/Descending

     - returns: Array of [Object] sorted by distance
     */
    func sort(ascending: Bool = true, distanceKey: ReferenceWritableKeyPath<Element, Double?>) -> [Iterator.Element] {

        return self.sorted(by: { (obj1, obj2) -> Bool in

            guard let dist1 = obj1[keyPath: distanceKey] else { return false }
            guard let dist2 = obj2[keyPath: distanceKey] else { return true }

            if ascending {
                return dist1 < dist2
            } else {
                return dist1 > dist2
            }
        })
    }
}

// MARK: - Private core extensions
extension RealmCollection where Element: Object {

    /**
     Add distance to sort results

     - parameter center:       Center coordinate
     - parameter latitudeKey:  Set to use different latitude key in query (default: "lat")
     - parameter longitudeKey: Set to use different longitude key in query (default: "lng")

     - returns: Array of results sorted
     */
    func addDistance(center: CLLocationCoordinate2D,
                     distanceKey: ReferenceWritableKeyPath<Element, Double?>,
                     latitudeKey: KeyPath<Element, Float?>,
                     longitudeKey: KeyPath<Element, Float?>) -> [Element] {

        return self.map { obj in

            // Calculate distance
            if let latitude = obj[keyPath: latitudeKey], let longitude = obj[keyPath: longitudeKey] {
                let location = CLLocationCoordinate2DMake(Double(latitude), Double(longitude))

                obj[keyPath: distanceKey] = location.distanceMeters(to: center)
            }
            return obj

        }
    }
}
