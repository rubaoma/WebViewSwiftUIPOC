//
//  ContentView.swift
//  WebViewPOC
//
//  Created by Rubens Moura Augusto on 04/04/25.
//

import SwiftUI
import WebKit

class WebViewWrapper: NSObject, ObservableObject {
    let webView = WKWebView()
    let canGobackStr: String = "canGoBack"
    @Published var canGoBack: Bool = false
    
    override init(){
        super.init()
        webView.addObserver(self, forKeyPath: canGobackStr, options: .new, context: nil)
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: canGobackStr)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == canGobackStr {
            DispatchQueue.main.async {
                self.canGoBack = self.webView.canGoBack
            }
        }
    }
    
    func goBack() {
        webView.goBack()
    }
    
}

struct WebView: UIViewRepresentable {
    let url: URL
//    let webView = WKWebView()
    var wrapper: WebViewWrapper
    
    func makeUIView(context: Context) -> WKWebView {
        wrapper.webView.navigationDelegate = context.coordinator
        wrapper.webView.load(URLRequest(url: url))
        return wrapper.webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let title = webView.title, !title.isEmpty {
                    NotificationCenter.default.post(name: .updateTitle, object: title)
                } else {
                    NotificationCenter.default.post(name: .updateTitle, object: "WebView")
                }
            }
        }
    }
}

extension Notification.Name {
    static  let updateTitle = Notification.Name("updateTitle")
}

struct ContentView: View {
    @State private var title: String = "WebviewPOC"
    @StateObject private var webViewWrapper = WebViewWrapper()
    
    let urlString = "http://localhost:8000/index.html"
    
    var body: some View {
        NavigationView {
            WebView(url: URL(string: urlString)!, wrapper: webViewWrapper)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        backButton
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .updateTitle)) {
                    notification in
                    if let newTitle = notification.object as? String, !newTitle.isEmpty {
                        title = newTitle
                    } else {
                        title = "WebviewPOC2"
                    }
                }
        }
    }
    
    var backButton: some View {
        Button(action: {
            if webViewWrapper.canGoBack {
                webViewWrapper.goBack()
            } else {
                exit(0)
            }
        }) {
            Image(systemName: "chevron.backward")
        }
        .disabled(!webViewWrapper.canGoBack)
    }
}

