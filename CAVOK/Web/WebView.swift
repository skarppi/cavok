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

    @StateObject var viewModel: ViewModel

    init() {
        let model = ViewModel()
        model.link = links.first

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .topLeading) {
                LinkWebView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if viewModel.progress < 1.0 {
                    ProgressView(value: viewModel.progress,
                                 total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(trailing:
                Picker("", selection: $viewModel.link) {
                    ForEach(links, id: \.self) { link in
                        Text(link.title)
                            .tag(link as Link?)
                    }}
                        .pickerStyle(SegmentedPickerStyle())
                        .labelsHidden()
            )
        }
        //progressView.tintColor = #colorLiteral(red: 0.6576176882, green: 0.7789518833, blue: 0.2271372974, alpha: 1)
    }
}

class ViewModel: ObservableObject {

    @Published var link: Link?
    @Published var progress: Double = 0.0
}

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView()
    }
}

struct LinkWebView: UIViewRepresentable {

    let webView = WKWebView()

    @ObservedObject var viewModel: ViewModel

    func makeUIView(context: UIViewRepresentableContext<LinkWebView>) -> WKWebView {

        webView.navigationDelegate = context.coordinator

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
        Coordinator(viewModel: viewModel, webView: webView)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        private var viewModel: ViewModel

        private var observer: NSKeyValueObservation?

        init(viewModel: ViewModel, webView: WKWebView) {
            self.viewModel = viewModel
            super.init()

            observer = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                viewModel.progress = webView.estimatedProgress
            }
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
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            if !error.isCancelled {
                webView.errorPage(error: error)
            }
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
