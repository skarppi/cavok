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
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var observationLabel: UILabel!
    
    @IBOutlet weak var metars: UILabel!
    
    @IBOutlet weak var tafs: UILabel!
    
    @IBOutlet var gripperTopConstraint: NSLayoutConstraint!
    
    private var closed: (() -> ()) = { () -> () in
        
    }
    
    func setup(closed: @escaping (() -> ()), presentation: ObservationPresentation, obs: Observation, observations: Observations) {
        self.closed = closed
        
        func highlight(observation: Observation) -> NSAttributedString {
            let attributed = NSMutableAttributedString(string: observation.raw)
            
            let mapped = presentation.mapper(observation)
            if let value = mapped.value, let source = mapped.source {
                let cgColor = presentation.ramp.color(for: Int32(value))
                attributed.addAttribute(NSAttributedStringKey.foregroundColor.rawValue, value: UIColor(cgColor: cgColor), pattern: source)
            }
            return attributed
        }
        
        titleLabel.text = obs.station?.name ?? "-"
        titleLabel.sizeToFit()
        
        add(header: nil, content: [highlight(observation: obs)], to: observationLabel, after: titleLabel)
        
        let metarHistory = observations.metars.reversed().map{ metar in
            return highlight(observation: metar)
        }
        if !metarHistory.isEmpty {
            add(header: "METAR history", content: metarHistory, to: self.metars, after: observationLabel)
        }

        if obs as? Taf == nil {
            let tafHistory = observations.tafs.reversed().map{ taf in
                return highlight(observation: taf)
            }
            if !tafHistory.isEmpty {
                add(header: "TAF", content: tafHistory, to: tafs, after: metars)
            }
        }
        
        drawerDisplayModeDidChange(drawer: pulley)
    }
    
    private func add(header: String?, content: [NSAttributedString], to label: UILabel, after: UILabel) {
        label.frame.origin.y = after.frame.maxY + 5
        
        let text = NSMutableAttributedString()
        if let header = header {
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            
            text.append(NSAttributedString(string: header + "\n", attributes: [
                NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14),
                NSAttributedStringKey.paragraphStyle: paragraphStyle
                ]))
        }
        
        content.forEach { str in
            text.append(str)
            text.append(NSAttributedString(string: "\n"))
        }
        
        label.attributedText = text
        label.sizeToFit()
        
        scrollView.contentSize.height = label.frame.maxY + 10
    }
    
    @IBAction func close(_ button: UIButton) {
        closed()
    }
    
    func drawerDisplayModeDidChange(drawer: PulleyViewController) {
        gripperTopConstraint.isActive = drawer.currentDisplayMode == .bottomDrawer
    }
}

extension ObservationDrawerController: PulleyDrawerViewControllerDelegate {
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.closed, .collapsed, .partiallyRevealed]
    }
    
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return observationLabel.frame.maxY + (pulley.displayMode == .bottomDrawer ? bottomSafeArea : 5)
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        let currentContentHeight = scrollView.contentSize.height
        
        let maxAvailableHeight = UIApplication.shared.keyWindow!.frame.height
        if pulley.displayMode == .bottomDrawer {
            return min(maxAvailableHeight - bottomSafeArea - pulley.topInset, currentContentHeight + bottomSafeArea)
        } else {
            return min(maxAvailableHeight - pulley.topInset * 2, currentContentHeight)
        }
    }
}
