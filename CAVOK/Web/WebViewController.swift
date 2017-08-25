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
    
    @IBOutlet var topbar: UIView! = nil
    
    @IBOutlet var containerView : UIView! = nil
    
    @IBOutlet var urls : UISegmentedControl! = nil
    
    var webView: WKWebView!
    
    var links: [[String: String]] = []
    
    func contentBlockers() -> WKUserScript {
        let selectors = links.flatMap { $0["blockElements"] }
            .filter{ !$0.isEmpty }
            .joined(separator: ",")
        
        let source = "var styleTag = document.createElement('style');" +
            "styleTag.textContent = '\(selectors) { display:none!important; }';" +
        "document.documentElement.appendChild(styleTag);"
        
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
    
    override func loadView() {
        super.loadView()
        
        // default navigation bar color
        let grey: CGFloat = 247.0/255.0
        topbar.backgroundColor = UIColor(red: grey, green: grey, blue: grey, alpha: 1)
        
        if let links = UserDefaults.standard.array(forKey: "links") as? [[String: String]] {
            self.links = links
        }
        
        let userContentController = WKUserContentController()
        userContentController.addUserScript(contentBlockers())
        
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
            self.urls.insertSegment(withTitle: link["title"], at: index, animated: true)
        }
        
        if links.count > 0 {
            urls.selectedSegmentIndex = 0
        }
        
        urls.sizeToFit()
        
        load()
                
        if UIDevice.current.orientation.isLandscape {
            self.didRotate(from: .landscapeLeft)
        }
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if fromInterfaceOrientation.isPortrait {
            topbar.frame.origin.y = -13
        } else {
            topbar.frame.origin.y = 0
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
    
    @IBAction func load() {
        guard urls.selectedSegmentIndex != -1 else {
            return
        }
        
        guard let link = links[urls.selectedSegmentIndex]["url"] else {
            errorPage(msg: "No url configured for link index \(urls.selectedSegmentIndex)")
            return
        }
        
        guard let url = buildURL(link: link) else {
            errorPage(msg: "Bad url for \(link)")
            return
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

class WebModule: MapModule {
    required init(delegate: MapDelegate) {
        if let controller = delegate as? UIViewController {
            controller.performSegue(withIdentifier: "OpenBrowser", sender: self)
        }
    }
    
    func cleanup() {
    }
    
    func didTapAt(coord: MaplyCoordinate) {
    }
    
    func refresh() -> Promise<Void> {
        return Promise<Void>(value: ())
    }
    
    func configure(open: Bool) {
    }
    
    func render(frame: Int) {
    }
    
    func annotation(object: Any, parentFrame: CGRect) -> UIView? {
        return nil
    }
}
