//
//  TimeslotDrawerController.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 01.12.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import Pulley

class TimeslotDrawerController: UITableViewController {
    
    @IBOutlet weak var status: UILabel!

    @IBOutlet weak var timeslots: TimeslotControl! {
        didSet {
            timeslots.removeAllSegments()
        }
    }
    
    @IBOutlet var gripper: UIView!
    
    @IBOutlet var gripperTopConstraint: NSLayoutConstraint!
    
    fileprivate weak var module: MapModule?
    
    override func viewWillAppear(_ animated: Bool) {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
        refreshControl.bounds = refreshControl.bounds.offsetBy(dx: 0, dy: -10)
        tableView.alwaysBounceVertical = false
        
        self.refreshControl = refreshControl
    }
    
    func setModule(module: MapModule?) {
        self.module = module
    }
    
    @IBAction func timeslotChanged() {
        module?.render(frame: timeslots.selectedSegmentIndex)
    }
    
    func setStatus(error: Error) {
        switch error {
        case let Weather.error(msg):
            setStatus(text: msg)
        default:
            print(error)
            setStatus(text: error.localizedDescription)
        }
        
    }
    
    func setStatus(text: String?, color: UIColor = UIColor.red) {
        if let text = text {
            status.textColor = color
            status.text = "\(text)"
        }
    }
    
    func reset(timeslots toload: [Timeslot], selected frame: Int) {
        timeslots.removeAllSegments()
        for (index, slot) in toload.enumerated() {
            timeslots.insertSegment(withTitle: slot.title, at: index, animated: true)
        }
        
        timeslots.selectedSegmentIndex = frame
        
        stopSpinning()
    }
    
    func update(color: UIColor, at segment: Int) {
        timeslots.updateSegment(color: color, at: segment)
    }
    
    @objc func refresh() {
        setControls(hidden: true)
        
        module?.refresh()
            .catch(Messages.show)
            .finally(stopSpinning)
    }
    
    func startSpinning() {
        setControls(hidden: true)
        
        self.refreshControl?.beginRefreshing()
    }
    
    private func setControls(hidden: Bool) {
        status.isHidden = hidden
        timeslots.isHidden = hidden
        gripper.isHidden = hidden
    }
    
    func stopSpinning() {
        refreshControl?.endRefreshing()
        setControls(hidden: false)
        tableView.contentOffset.y = 0
    }
}

extension TimeslotDrawerController: PulleyDrawerViewControllerDelegate {
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.partiallyRevealed]
    }
    
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 20 + (pulley.currentDisplayMode == .bottomDrawer ? bottomSafeArea : 0)
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 80 + (pulley.currentDisplayMode == .bottomDrawer ? bottomSafeArea : 0)
    }
    
    func drawerDisplayModeDidChange(drawer: PulleyViewController) {
        gripperTopConstraint.isActive = drawer.currentDisplayMode == .bottomDrawer
    }
}
