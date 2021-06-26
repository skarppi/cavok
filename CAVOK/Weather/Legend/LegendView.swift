//
//  LegendGradientView.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 17/10/2016.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

public struct Legend {
    var unit: String
    var gradient: [CGColor]
    var titles: [String]
}

class LegendView: UIView {
    func loaded(legend: Legend) {
        self.subviews.forEach { $0.removeFromSuperview() }
        layer.sublayers?.removeAll()

        let legendText = UITextView(frame: CGRect(x: 17, y: 0, width: 32, height: frame.height))
        legendText.text = legend.unit + "\n" + legend.titles.reversed().joined(separator: "\n")
        legendText.textContainer.lineFragmentPadding = 0
        legendText.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        legendText.font = UIFont.systemFont(ofSize: 12)
        legendText.alpha = 0.7
        legendText.backgroundColor = UIColor.clear
        self.addSubview(legendText)

        let gradientLayer = CAGradientLayer()
        let ramp = legend.gradient
        gradientLayer.colors = [
            ramp[5],
            ramp[4],
            ramp[4],
            ramp[3],
            ramp[3],
            ramp[2],
            ramp[2],
            ramp[1],
            ramp[1],
            ramp[0]
        ]
        gradientLayer.locations = [ 0.15, 0.18, 0.27, 0.36, 0.45, 0.54, 0.63, 0.72, 0.81, 0.85]
        gradientLayer.frame.origin = CGPoint(x: 0, y: 15)
        gradientLayer.frame.size = CGSize(width: 15, height: frame.height - gradientLayer.frame.origin.y)

        self.layer.addSublayer(gradientLayer)

        self.isHidden = false
    }

}
