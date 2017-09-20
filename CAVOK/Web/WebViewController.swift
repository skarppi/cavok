//
//  WebViewController.swift
//  Lentosaa
//
//  Created by Juho Kolehmainen on 22.06.15.
//  Copyright (c) 2015 Juho Kolehmainen. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import PromiseKit

class WebViewController: UIViewController {
    
    @IBOutlet weak var containerView : UIView! = nil
    
    @IBOutlet weak var urls : UISegmentedControl! = nil
    
    private var webView: WKWebView!
    
    private var links: [Link] = []
    
    override func loadView() {
        super.loadView()
        
        links = Links.load()
        
        let userContentController = WKUserContentController()
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        
        webView = WKWebView(frame: containerView.bounds, configuration: configuration)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(webView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.urls.removeAllSegments()
        links.enumerated().forEach { (index, link) in
            self.urls.insertSegment(withTitle: link.title, at: index, animated: true)
        }
        
        if links.count > 0 {
            urls.selectedSegmentIndex = 0
        }
        
        urls.sizeToFit()
        
        load()
    }
    
    @IBAction func close() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func errorPage(msg: String) {
        let html = "<!doctype html><html><body><div style=\"width: 100%%; text-align: center; font-size: 36pt;\">\(msg)</div></body></html>"
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    private func buildURL(link: String) -> URL? {
        if link.contains("{lat}") || link.contains("{lon") {
            if let deg = LastLocation.load()?.deg {
                let lat = String(deg.y) + (deg.y > 0 ? "N" : "S")
                let lon = String(deg.x) + (deg.x > 0 ? "E" : "W")
                
                return URL(string: link.replace("{lat}", with: lat).replace("{lon}", with: lon))
            } else {
                return nil
            }
        } else {
            return URL(string: link)
        }
    }
    
    private func block(elements: String) -> WKUserScript {
        let source = "var styleTag = document.createElement('style');" +
            "styleTag.textContent = '\(elements) { display:none!important; }';" +
        "document.documentElement.appendChild(styleTag);"
        
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
    
    @IBAction func load() {
        guard urls.selectedSegmentIndex != -1 else {
            return
        }
        
        let link = links[urls.selectedSegmentIndex]
        
        guard let url = buildURL(link: link.url) else {
            errorPage(msg: "Bad url for \(link)")
            return
        }
        
        let content = webView.configuration.userContentController
        content.removeAllUserScripts()
        
        if let elements = link.blockElements {
            let script = block(elements: elements)
            content.addUserScript(script)
        }
        
        webView.load(URLRequest(url: url))
    }
}

// MARK: WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let host = navigationAction.request.url?.host {
            if host.contains("googleads") {
                return decisionHandler(.cancel)
            }
        }
        return decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if !error.isCancelledError {
            errorPage(msg: error.localizedDescription)
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
