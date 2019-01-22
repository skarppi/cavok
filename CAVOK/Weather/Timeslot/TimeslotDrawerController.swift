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
    
    private var scrollingLocked: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
        refreshControl.bounds = refreshControl.bounds.offsetBy(dx: 0, dy: -10)
        
        self.refreshControl = refreshControl
    }
    
    override func viewWillAppear(_ animated: Bool) {
        drawerDisplayModeDidChange(drawer: pulley)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !scrollingLocked && scrollView.contentOffset.y < -40 {
            // when pulling down trigger refresh earlier
            if !refreshControl!.isRefreshing {
                refreshControl!.beginRefreshing()
                refresh()
            }
        } else if (scrollView.contentOffset.y >= 0) {
            // prevent bounce up
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0), animated: false)
        }
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        scrollingLocked = true
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        scrollingLocked = false
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
        tableView.setContentOffset(CGPoint(x:0, y:tableView.contentOffset.y - refreshControl!.frame.size.height), animated: false)

        refreshControl?.beginRefreshing()
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
        scrollingLocked = false
    }
}

extension TimeslotDrawerController: PulleyDrawerViewControllerDelegate {
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.collapsed]
    }
    
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        let bottomSpace = bottomSafeArea > 0 ? bottomSafeArea : 10
        return 70 + (pulley.currentDisplayMode == .drawer ? bottomSpace : 0)
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 0
    }
    
    func drawerDisplayModeDidChange(drawer: PulleyViewController) {
        gripperTopConstraint.isActive = drawer.currentDisplayMode == .drawer
    }
}
