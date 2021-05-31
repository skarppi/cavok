//
//  WebView.swift
//  Lentosaa
//
//  Created by Juho Kolehmainen on 22.06.15.
//  Copyright (c) 2015 Juho Kolehmainen. All rights reserved.
//

import SwiftUI
import UIKit
import WebKit
import PromiseKit

struct WebView: View {
    var links = Links.load()

    @StateObject var viewModel = ViewModel()

    init() {
        viewModel.link = links.first
    }

    var body: some View {
        NavigationView {
            LinkWebView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(
                    trailing:
                        Group {
                            Picker("", selection: $viewModel.link) {
                                ForEach(links, id: \.self) { link in
                                    Text(link.title)
                                        .tag(link as Link?)
                                }}
                                    .pickerStyle(SegmentedPickerStyle())
                                    .labelsHidden()

                            ProgressView(value: viewModel.progress,
                                         total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle())
                            //progressView.tintColor = #colorLiteral(red: 0.6576176882, green: 0.7789518833, blue: 0.2271372974, alpha: 1)
                        }
                )
        }
    }
}

class ViewModel: ObservableObject {

    @Published var link: Link?
    @Published var progress: Double?
}

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView()
    }
}

struct LinkWebView: UIViewRepresentable {

    @ObservedObject var viewModel: ViewModel

    @State var observation: NSKeyValueObservation?

    func makeUIView(context: UIViewRepresentableContext<LinkWebView>) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator

        observation  = webView.observe(\.estimatedProgress, options: .new) { _, change in
            print("change ", webView.estimatedProgress, change)
            viewModel.progress = webView.estimatedProgress
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<LinkWebView>) {

        guard let url = viewModel.link?.buildURL() else {
            return
        }

        if !(uiView.url?.absoluteString.contains(url.host ?? "") ?? false) {
                let request = URLRequest(url: url)
                uiView.load(request)
            load(webView: uiView)
            print("Update \(url)")
        }
    }

    func load(webView: WKWebView) {
        guard let url = viewModel.link?.buildURL() else {
            webView.errorPage(msg: "Invalid url:  \(viewModel.link?.url ?? "")")
            return
        }

        webView.blockElement(elements: viewModel.link?.blockElements)
        webView.load(URLRequest(url: url))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self.viewModel)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        private var viewModel: ViewModel

        init(_ viewModel: ViewModel) {
            self.viewModel = viewModel
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let host = navigationAction.request.url?.host {
                if host.contains("googleads") {
                    return decisionHandler(.cancel)
                }
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//            viewModel.progress = 0
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//            viewModel.progress = nil
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            if !error.isCancelled {
                webView.errorPage(error: error)
            }
//            viewModel.progress = nil
        }
    }
}

extension WKWebView {
    func errorPage(error: Error) {
        errorPage(msg: error.localizedDescription)
    }

    func errorPage(msg: String) {
        let html = """
            <!doctype html><html><body><div style=\"width: 100%%; text-align: center; font-size: 36pt;\">
            \(msg)
        </div></body></html>
"""

        self.loadHTMLString(html, baseURL: nil)
    }

    func blockElement(elements: String?) {
        let content = configuration.userContentController
        content.removeAllUserScripts()

        guard let elements = elements, elements.length > 0 else {
            return
        }

        let source = "var styleTag = document.createElement('style');" +
            "styleTag.textContent = '\(elements) { display:none!important; }';" +
            "document.documentElement.appendChild(styleTag);"

        let script = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        content.addUserScript(script)
    }
}
