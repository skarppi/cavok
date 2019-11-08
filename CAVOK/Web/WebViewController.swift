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

var myContext = 0

class WebViewController: UIViewController {
    
    @IBOutlet weak var containerView : UIView! = nil
    
    @IBOutlet weak var urls : UISegmentedControl! = nil
    
    private var webView: WKWebView!
    
    fileprivate var progressView: UIProgressView!
    
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
        
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.autoresizingMask = [.flexibleWidth]
        progressView.tintColor = #colorLiteral(red: 0.6576176882, green: 0.7789518833, blue: 0.2271372974, alpha: 1)
        progressView.frame = CGRect(x: 0, y: 0, width: containerView.bounds.size.width, height: 50)
        containerView.addSubview(progressView)
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
        
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: &myContext)
        
        load()
    }
    
    //observer
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let change = change else { return }
        if context != &myContext {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == "estimatedProgress" {
            if let progress = (change[NSKeyValueChangeKey.newKey] as AnyObject).floatValue {
                progressView.progress = progress;
            }
            return
        }
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
        progressView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if !error.isCancelled {
            errorPage(msg: error.localizedDescription)
        }
        
        progressView.isHidden = true
    }
}
