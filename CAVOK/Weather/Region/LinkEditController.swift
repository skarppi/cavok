//
//  LinkEditController.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 03.09.2017.
//  Copyright © 2017 Juho Kolehmainen. All rights reserved.
//

import Foundation
import os.log

class LinkEditController: UIViewController, UINavigationControllerDelegate {

    // MARK: Properties
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var blockerTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!

    var link: Link?

    override func viewDidLoad() {
        super.viewDidLoad()

        titleTextField.delegate = self
        linkTextField.delegate = self
        blockerTextField.delegate = self

        if let link = link {
            navigationItem.title = link.title
            titleTextField.text = link.title
            linkTextField.text = link.url
            blockerTextField.text = link.blockElements
        }

        updateSaveButtonState()
    }

    // MARK: Navigation

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            return
        }

        let title = titleTextField.text ?? ""
        let url = linkTextField.text ?? ""
        let blocker = blockerTextField.text

        link = Link(title: title, url: url, blockElements: blocker)
    }

    // MARK: Private Methods

    fileprivate func updateSaveButtonState() {
        // Disable the Save button if the text field is empty.
        let text = titleTextField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
}

// MARK: UITextFieldDelegate
extension LinkEditController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing.
        saveButton.isEnabled = false
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()

        if textField === titleTextField {
            navigationItem.title = textField.text
        }
    }
}
