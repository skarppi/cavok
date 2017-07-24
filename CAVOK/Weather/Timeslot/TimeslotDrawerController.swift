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
    
    func loaded(frame:Int, timeslots: [Timeslot]) {
        self.timeslots.removeAllSegments()
        for (index, slot) in timeslots.enumerated() {
            self.timeslots.insertSegment(with: slot, at: index, animated: true)
        }
        
        self.timeslots.selectedSegmentIndex = frame
    }
}

// MARK: - UITextFieldDelegate
extension TimeslotDrawerController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        module?.refresh()
        return false
    }
}

extension TimeslotDrawerController: PulleyDrawerViewControllerDelegate {
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.closed, .collapsed]
    }
    
    func collapsedDrawerHeight() -> CGFloat {
        return 70
    }
    
    func partialRevealDrawerHeight() -> CGFloat {
        return 150
    }
}

extension UITextField {
    func applyRestartButton() {
        clearButtonMode = .never
        rightViewMode   = .always

        let button = UIButton(frame: CGRect(x:0, y:0, width:16, height:16))
        button.setImage(UIImage(named: "Restart")!, for: .normal)
        
        if let delegate = delegate {
         button.addTarget(delegate, action: #selector(delegate.textFieldShouldBeginEditing(_:)), for: .touchUpInside)
        }
        
        rightView = button
    }
}
