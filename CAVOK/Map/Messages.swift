//
//  SwiftMessages+Additions.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 18.07.2017.
//  Copyright © 2017 Juho Kolehmainen. All rights reserved.
//

import Foundation

import SwiftMessages

class Messages {

    class func setup() {
        SwiftMessages.defaultConfig.presentationContext = .window(windowLevel: UIWindow.Level.normal)

        SwiftMessages.defaultConfig.duration = .forever
    }

    class func showCopiedToClipboard() {
        Messages.show(text: "Copied to clipboard", seconds: 2)
    }

    class func show(error: Error) {
        switch error {
        case let Weather.error(msg):
            print("show weather error: \(msg)")
            Messages.show(error: msg)
        default:
            print("show error: \(error)")
            Messages.show(error: error.localizedDescription)
        }
    }

    class func show(error: String) {
        Messages.show(text: error, theme: .error, seconds: 5)
    }

    class func show(text: String, theme: Theme = .info, seconds: Double? = nil) {
        var config = SwiftMessages.defaultConfig
        if let seconds = seconds {
            config.duration = .seconds(seconds: seconds)
        }

        SwiftMessages.hideAll()

        let view = MessageView.viewFromNib(layout: .cardView)
        view.titleLabel?.isHidden = true
        view.button?.isHidden = true
        view.configureTheme(.info)
        view.configureContent(body: text)
        SwiftMessages.show(config: config, view: view)
    }

    class func hide() {
        DispatchQueue.main.async {
            SwiftMessages.hideAll()
        }
    }
}
