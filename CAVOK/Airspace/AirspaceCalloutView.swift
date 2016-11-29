//
//  AirspaceCalloutView.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 25.02.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class AirspaceCalloutView: UIView {
    
    init(attributes: AirspaceAttributes, parentFrame: CGRect) {
        
        let maxWidth = min(parentFrame.size.width - 100, 500)
        let frame = CGSize(width: maxWidth, height: 100);
        
        let titleLabel = UILabel(frame: CGRect(origin: CGPoint.zero, size: frame))
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        titleLabel.text = attributes.name
        titleLabel.sizeToFit()
        
        let label = UILabel(frame:CGRect(origin: CGPoint(x: 0, y: titleLabel.frame.size.height + 5), size: frame))
        label.font = UIFont.systemFont(ofSize: 12)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.text = attributes.description
        label.sizeToFit()
        
        super.init(frame: CGRect(x: 0, y: 0, width: maxWidth, height: titleLabel.frame.size.height + label.frame.size.height))
        
        addSubview(titleLabel)
        addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
