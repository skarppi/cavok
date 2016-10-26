//
//  ObservationCalloutView.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 31.01.15.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class ObservationCalloutView: UIView {
    
    init(value: Int?, obs: Observation, ramp: ColorRamp, parentFrame: CGRect) {
        let titleAttr = NSMutableAttributedString(string: "\(obs.station!.name) (");
        
        let valueStr = value.map {String($0)} ?? "-"
        
        let valueColor:CGColor = ramp.color(for: value.map { Int32($0) } ?? 0)
        let valueAttributes = [NSForegroundColorAttributeName : UIColor(cgColor: valueColor)]
        titleAttr.append(NSAttributedString(string: valueStr, attributes:valueAttributes))
        
        titleAttr.append(NSAttributedString(string: " \(ramp.unit))"))
        
        let maxWidth = min(parentFrame.size.width - 100, 500)
        let frame = CGSize(width: maxWidth, height: 100);
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        titleLabel.attributedText = titleAttr
        titleLabel.sizeToFit()
        
        let label = UILabel(frame:CGRect(x: 0, y: titleLabel.frame.size.height + 5, width: frame.width, height: frame.height))
        label.font = UIFont.systemFont(ofSize: 12)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.text = obs.raw
        label.sizeToFit()
        
        super.init(frame: CGRect(x: 0, y: 0, width: maxWidth, height: titleLabel.frame.size.height + label.frame.size.height))
        
        addSubview(titleLabel)
        addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
