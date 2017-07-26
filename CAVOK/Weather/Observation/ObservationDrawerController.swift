//
//  ObservationDrawerController.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 25.07.2017.
//  Copyright © 2017 Juho Kolehmainen. All rights reserved.
//

import Foundation
import Pulley

class ObservationDrawerController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var observationLabel: UILabel!
    
    @IBOutlet weak var metars: UILabel!
    
    @IBOutlet weak var tafs: UILabel!
    
    private var closed: (Void) -> Void = { Void -> Void in
    }
    
    func setup(closed: @escaping (Void) -> Void, value: Int?, obs: Observation, observations: Observations, ramp: ColorRamp) {
        self.closed = closed
        
        let titleAttr = NSMutableAttributedString(string: "\(obs.station!.name) (");
        
        let title = value.map {String($0)} ?? "-"
        
        let cgColor = ramp.color(for: value.map { Int32($0) } ?? 0)
        let attributes = [NSForegroundColorAttributeName : UIColor(cgColor: cgColor)]
        titleAttr.append(NSAttributedString(string: title, attributes:attributes))
        titleAttr.append(NSAttributedString(string: " \(ramp.unit))"))

        titleLabel.attributedText = titleAttr
        titleLabel.sizeToFit()
        
        observationLabel.frame.origin.y = titleLabel.frame.maxY + 8
        observationLabel.text = obs.raw
        observationLabel.sizeToFit()
        
        let labels: [String] = observations.metars.map{ metar in
            return metar.raw
        }

        metars.frame.origin.y = titleLabel.frame.maxY + 8
        metars.text = labels.joined(separator: "\n")
        metars.sizeToFit()
        
        metars.frame.origin.y = observationLabel.frame.maxY + 8
    }
    
    @IBAction func close(_ button: UIButton) {
        closed()
    }
}

extension ObservationDrawerController: PulleyDrawerViewControllerDelegate {
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.closed, .collapsed, .partiallyRevealed]
    }
    
    func collapsedDrawerHeight() -> CGFloat {
        return observationLabel.frame.maxY + 8
    }
    
    func partialRevealDrawerHeight() -> CGFloat {
        return metars.frame.maxY + 8
    }
}
