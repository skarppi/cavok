//
//  UIView+Additions.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 17.06.2017.
//  Copyright © 2017 Juho Kolehmainen. All rights reserved.
//

import Foundation
import SwiftUI

extension UIView {

    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

extension UIButton {
    @IBInspectable var padding: CGFloat {
        get {
            return contentEdgeInsets.bottom
        }
        set {
            contentEdgeInsets = UIEdgeInsets.init(top: newValue, left: newValue, bottom: newValue, right: newValue)
        }
    }
}

extension UIApplication {
    static var withSafeAreas: Bool {
        return shared.delegate?.window??.safeAreaInsets != .zero
    }
}

extension View {
    func phoneOnlyStackNavigationView() -> some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return AnyView(self.navigationViewStyle(StackNavigationViewStyle()))
        } else {
            return AnyView(self)
        }
    }
}
