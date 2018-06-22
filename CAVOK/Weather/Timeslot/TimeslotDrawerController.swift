//
//  TimeslotDrawerController.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 01.12.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation
import Pulley

class TimeslotDrawerController: UIViewController {
    
    @IBOutlet weak var status: UITextField!

    @IBOutlet weak var timeslots: TimeslotControl!
    
    fileprivate weak var module: MapModule?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timeslots.removeAllSegments()
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
        
        if status.rightView == nil {
            // running on first time
            status.applyRestartButton()
        }
    }
    
    func update(color: UIColor, at segment: Int) {
        timeslots.updateSegment(color: color, at: segment)
    }
}

// MARK: - UITextFieldDelegate
extension TimeslotDrawerController: UITextFieldDelegate {
    
    func startSpinning() {
        if let button = status.rightView as? UIButton,
            let spiner = button.layer.sublayers?.last as? SpinerLayer,
            !button.isSelected {
            button.isSelected = true
            spiner.animation()
        }
    }
    
    func stopSpinning() {
        if let button = status.rightView as? UIButton,
            let spiner = button.layer.sublayers?.last as? SpinerLayer,
            button.isSelected {
            spiner.stopAnimation()
            button.isSelected = false
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        startSpinning()
        
        module?.refresh()
            .catch(Messages.show)
            .finally(stopSpinning)
        
        return false
    }
}

extension TimeslotDrawerController: PulleyDrawerViewControllerDelegate {
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        if timeslots.numberOfSegments > 0 {
            return [.partiallyRevealed]
        } else {
            return [.collapsed, .partiallyRevealed]
        }
    }
    
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 20 + (pulley.currentDisplayMode == .bottomDrawer ? bottomSafeArea : 0)
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 70 + (pulley.currentDisplayMode == .bottomDrawer ? bottomSafeArea : 0)
    }
    
    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        if drawer.drawerPosition == .collapsed {
            timeslots.isHidden = true
//            setStatus(text: "...", color: UIColor.gray)
            startSpinning()
            timeslots.removeAllSegments()
        } else {
            timeslots.isHidden = timeslots.numberOfSegments == 0
            stopSpinning()
        }
    }
}

extension UITextField {
    func applyRestartButton() {
        clearButtonMode = .never
        rightViewMode   = .always

        let button = UIButton(frame: CGRect(x:0, y:0, width:16, height:16))
        button.setImage(UIImage(named: "Restart"), for: .normal)
        button.setImage(UIImage(), for: .selected)
        
        let spiner = SpinerLayer(frame: button.frame)
        button.layer.addSublayer(spiner)
        
        if let delegate = delegate {
            button.addTarget(delegate, action: #selector(delegate.textFieldShouldBeginEditing(_:)), for: .touchUpInside)
        }
        
        rightView = button
    }
}
