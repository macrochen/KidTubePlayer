// BilibiliPlayerView.swift (最终的进程隔离版)

import SwiftUI
import WebKit

struct BilibiliPlayerView: UIViewRepresentable {
    let videoID: String
    let page: Int

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // 【核心修改】为每个 WebView 实例创建一个全新的、独立的进程池
        // 这可以彻底杜绝任何形式的缓存或状态共享
        configuration.processPool = WKProcessPool()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        // ... 其他 webView 设置保持不变 ...
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                html, body, iframe {
                    width: 100%; height: 100%; margin: 0; padding: 0;
                    border: none; overflow: hidden; background-color: #000;
                }
            </style>
        </head>
        <body>
            <iframe src="https://player.bilibili.com/player.html?bvid=\(videoID)&p=\(page)&autoplay=1&high_quality=1&danmaku=0&muted=true"
                    scrolling="no" border="0" frameborder="no" framespacing="0"
                    allow="autoplay" allowfullscreen="true">
            </iframe>
        </body>
        </html>
        """
        webView.loadHTMLString(htmlString, baseURL: URL(string: "https://www.bilibili.com"))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}