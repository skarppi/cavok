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
        
        titleLabel.text = obs.station?.name ?? "-"
        
        add(header: nil, content: [presentation.highlight(observation: obs)], to: observationLabel, after: nil)
        
        let metarHistory = observations.metars.reversed().map{ metar in
            return presentation.highlight(observation: metar)
        }
        if !metarHistory.isEmpty {
            add(header: "METAR history", content: metarHistory, to: self.metars, after: observationLabel)
        }

        if obs as? Taf == nil {
            let tafHistory = observations.tafs.reversed().map{ taf in
                return presentation.highlight(observation: taf)
            }
            if !tafHistory.isEmpty {
                add(header: "TAF", content: tafHistory, to: tafs, after: metars)
            }
        }
        
        drawerDisplayModeDidChange(drawer: pulley)
    }
    
    private func add(header: String?, content: [NSAttributedString], to label: UILabel, after: UILabel?) {
        if let after = after {
            label.frame.origin.y = after.frame.maxY + 5
        }
        
        let text = NSMutableAttributedString()
        if let header = header {
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            
            text.append(NSAttributedString(string: header + "\n", attributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                NSAttributedString.Key.paragraphStyle: paragraphStyle
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
    
}

extension ObservationDrawerController: PulleyDrawerViewControllerDelegate {
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.collapsed, .partiallyRevealed]
    }
    
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return scrollView.frame.origin.y + observationLabel.frame.maxY + (pulley.displayMode == .drawer ? bottomSafeArea : 0)
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        let currentContentHeight = scrollView.frame.origin.y + scrollView.contentSize.height
        
        let maxAvailableHeight = UIApplication.shared.windows.first {$0.isKeyWindow}!.frame.height
        if pulley.displayMode == .drawer {
            return min(maxAvailableHeight - bottomSafeArea - pulley.drawerTopInset, currentContentHeight + bottomSafeArea)
        } else {
            return min(maxAvailableHeight - pulley.drawerTopInset * 2, currentContentHeight)
        }
    }
    
    func drawerDisplayModeDidChange(drawer: PulleyViewController) {
        gripperTopConstraint.isActive = drawer.currentDisplayMode == .drawer
    }
}
