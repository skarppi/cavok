//
//  UIView+Additions.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 17.06.2017.
//  Copyright © 2017 Juho Kolehmainen. All rights reserved.
//

import Foundation

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
            contentEdgeInsets = UIEdgeInsetsMake(newValue, newValue, newValue, newValue)
        }
    }
}


extension UIApplication {
    static var withSafeAreas: Bool {
        return shared.delegate?.window??.safeAreaInsets != .zero
    }
}
