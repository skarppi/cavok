//
//  DrawerViewController.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 01.12.16.
//  Copyright © 2016 Juho Kolehmainen. All rights reserved.
//

import Foundation

class DrawerViewController: UIViewController {

    @IBOutlet var gripperView: UIView!
    
    @IBOutlet weak var bottomView: UIView!

    @IBOutlet weak var status: UITextField!

    @IBOutlet weak var timeslots: TimeslotView!
    
    fileprivate var module: MapModule?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gripperView.layer.cornerRadius = 2.5
    }
    
    func setModule(module: MapModule?) {
        self.module = module
    }
    
    @IBAction func timeslotChanged() {
        module?.render(frame: timeslots.selectedSegmentIndex)
    }
    
    fileprivate func animateTimeslots(show: Bool) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            let height: CGFloat = (show ? 80 : 40)
            //self.bottomView.frame.origin = CGPoint(x: 0, y: self.view.bounds.height - height)
        })
    }
}

// MARK: - DrawerDelegate
extension DrawerViewController : DrawerDelegate {
    
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
    
    func loaded(frame:Int?, timeslots: [Timeslot], legend: Legend) {
        if let frame = frame {
            self.timeslots.removeAllSegments()
            for (index, slot) in timeslots.enumerated() {
                self.timeslots.insertSegment(with: slot, at: index, animated: true)
            }
            
            animateTimeslots(show: true)
            
            self.timeslots.selectedSegmentIndex = frame
        } else {
            animateTimeslots(show: false)
        }
    }
}

// MARK: - UITextFieldDelegate
extension DrawerViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == self.status {
            module?.refresh()
        }
        return false
    }
}
