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
        SwiftMessages.defaultConfig.presentationContext = .window(windowLevel: UIWindow.Level.normal.rawValue)
        
        SwiftMessages.defaultConfig.duration = .forever
    }
    
    static func messageView(backgroundColor: UIColor = UIColor.clear) -> MessageView {
        let status = MessageView.viewFromNib(layout: .statusLine)
        status.backgroundView.backgroundColor = backgroundColor
        return status
    }
    
    class func show(text: String) {
        print("show message: \(text)")
        
        let view = messageView()
        view.configureContent(body: text)

        Messages.show(view: view, seconds: nil)
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
        let view = messageView(backgroundColor: UIColor.red.withAlphaComponent(0.5))
        view.configureContent(body: error)
        Messages.show(view: view, seconds: 5)
    }
    
    class func show(view: MessageView, seconds: Double?) {
        var config = SwiftMessages.defaultConfig
        if let seconds = seconds {
            config.duration = .seconds(seconds: seconds)
        }
        
        SwiftMessages.hideAll()
        SwiftMessages.show(config: config, view: view)
    }
    
    class func hide() {
        DispatchQueue.main.async {
            SwiftMessages.hideAll()
        }
    }
}
