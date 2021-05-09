//
//  RightImageButton.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 01.09.2017.
//  Copyright © 2017 Juho Kolehmainen. All rights reserved.
//

import Foundation

@IBDesignable class RightImageButton: UIButton {

    @IBInspectable var imageAlpha: CGFloat = 1 {
        didSet {
            if let imageView = imageView {
                imageView.alpha = imageAlpha
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let imageView = imageView {
            imageView.alpha = imageAlpha
        }
    }
}
