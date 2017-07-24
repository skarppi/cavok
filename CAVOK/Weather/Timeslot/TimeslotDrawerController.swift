//
//  TimeslotDrawerController.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 01.12.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class TimeslotDrawerController: UIViewController {
    
    @IBOutlet weak var bottomView: UIView!

    @IBOutlet weak var status: UITextField!

    @IBOutlet weak var timeslots: TimeslotControl!
    
    fileprivate weak var module: MapModule?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        if textField == self.status {
            module?.refresh()
        }
        return false
    }
}
