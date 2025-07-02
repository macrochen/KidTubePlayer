import SwiftUI
import WebKit

struct BilibiliPlayerView: UIViewRepresentable {
    // Bilibili 视频的 BV 号
    let videoID: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // 允许内联播放和自动播放
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // 使用 HTML 字符串来加载播放器，可以更好地控制样式和行为
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                html, body {
                    margin: 0;
                    padding: 0;
                    width: 100%;
                    height: 100%;
                    overflow: hidden;
                    background-color: #000;
                }
                iframe {
                    width: 100%;
                    height: 100%;
                    border: none;
                }
            </style>
        </head>
        <body>
            <iframe src="https://player.bilibili.com/player.html?bvid=\(videoID)&page=1&autoplay=1&high_quality=1&danmaku=0"
                    allow="autoplay; encrypted-media"
                    allowfullscreen>
            </iframe>
        </body>
        </html>
        """
        webView.loadHTMLString(htmlString, baseURL: nil)
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 无需更新
    }
}
