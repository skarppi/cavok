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
    
    @IBOutlet weak var bottomView: UIView!

    @IBOutlet weak var status: UITextField!

    @IBOutlet weak var timeslots: TimeslotControl!
    
    fileprivate weak var module: MapModule?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        status.applyRestartButton()
        
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
    }
    
    func update(color: UIColor, at segment: Int) {
        timeslots.updateSegment(color: color, at: segment)
    }
}

// MARK: - UITextFieldDelegate
extension TimeslotDrawerController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if let button = status.rightView as? UIButton, !button.isSelected {
            let spiner = button.layer.sublayers?.last as? SpinerLayer ?? {
                let spiner = SpinerLayer(frame: button.frame)
                button.layer.addSublayer(spiner)
                return spiner
            }()
            
            button.isSelected = true
            spiner.animation()
            
            module?.refresh()
                .catch(execute: Messages.show)
                .always {
                    spiner.stopAnimation()
                    button.isSelected = false
                }
        }
        return false
    }
}

extension TimeslotDrawerController: PulleyDrawerViewControllerDelegate {
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.closed, .collapsed]
    }
    
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 70 + (pulley.currentDisplayMode == .bottomDrawer ? bottomSafeArea : 0)
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return collapsedDrawerHeight(bottomSafeArea: bottomSafeArea)
    }
}

extension UITextField {
    func applyRestartButton() {
        clearButtonMode = .never
        rightViewMode   = .always

        let button = UIButton(frame: CGRect(x:0, y:0, width:16, height:16))
        button.setImage(UIImage(named: "Restart"), for: .normal)
        button.setImage(UIImage(), for: .selected)
        
        if let delegate = delegate {
            button.addTarget(delegate, action: #selector(delegate.textFieldShouldBeginEditing(_:)), for: .touchUpInside)
        }
        
        rightView = button
    }
}
