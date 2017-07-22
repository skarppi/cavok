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
        SwiftMessages.defaultConfig.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        SwiftMessages.defaultConfig.eventListeners.append({ event in
            switch event {
            case .willShow : UIApplication.shared.isStatusBarHidden = true
            case .didHide: UIApplication.shared.isStatusBarHidden = false
            default: break
            }
        })
        SwiftMessages.defaultConfig.duration = .forever
    }
    
    static func messageView(backgroundColor: UIColor = UIColor.clear) -> MessageView {
        let status = MessageView.viewFromNib(layout: .StatusLine)
        status.backgroundView.backgroundColor = backgroundColor
        return status
    }
    
    class func show(text: String) {
        print("show message: \(text)")
        
        SwiftMessages.hideAll()
        
        let view = messageView()
        view.configureContent(body: text)
        
        SwiftMessages.show(view: view)
    }
    
    class func show(error: Error) {
        
        var config = SwiftMessages.defaultConfig
        config.duration = .seconds(seconds: 5)
        
        let view = messageView(backgroundColor: UIColor.red.withAlphaComponent(0.5))
        
        switch error {
        case let Weather.error(msg):
            print("show weather error: \(msg)")
            view.configureContent(body: msg)
        default:
            print("show error: \(error)")
            view.configureContent(body: error.localizedDescription)
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
