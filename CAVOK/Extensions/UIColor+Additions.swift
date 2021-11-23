//
//  UIColor+Additions.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 18.7.2021.
//

import Foundation
import SwiftUI

extension UIColor {

    func lighter(by saturation: CGFloat) -> UIColor {
        var hue: CGFloat = 0, sat: CGFloat = 0
        var brt: CGFloat = 0, alpha: CGFloat = 0

        guard getHue(&hue, saturation: &sat, brightness: &brt, alpha: &alpha)
            else {return self}

        return UIColor(hue: hue,
                       saturation: max(sat - saturation, 0.0),
                       brightness: brt,
                       alpha: alpha)
    }
}

extension Color {
    public func lighter(by amount: CGFloat = 0.2) -> Self { Self(UIColor(self).lighter(by: amount)) }
}
