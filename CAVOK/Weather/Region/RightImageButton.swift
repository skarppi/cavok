//
//  RightImageButton.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 01.09.2017.
//  Copyright © 2017 Juho Kolehmainen. All rights reserved.
//

import Foundation

class RightImageButton: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let imageSize = imageView?.intrinsicContentSize {
            let width = imageSize.width - imageEdgeInsets.left - imageEdgeInsets.right
            let height = imageSize.height - imageEdgeInsets.bottom - imageEdgeInsets.top
            
            imageView?.frame = CGRect(
                x: round(bounds.width),
                y: round(bounds.height/2 - height/2),
                width: width,
                height: height)
        }
    }
}
