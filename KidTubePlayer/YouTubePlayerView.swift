import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {

    let videoID: String
    private let playbackRateKey = "youtubePlaybackRate"
    // 为每个视频创建一个独立的进度存储键
    private var progressKey: String { "progress-\(videoID)" }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let contentController = configuration.userContentController
        // 注册两个消息句柄：一个用于播放速度，一个用于播放进度
        contentController.add(context.coordinator, name: "playbackRateHandler")
        contentController.add(context.coordinator, name: "progressHandler")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // --- 读取已保存的设置 ---
        let savedRate = UserDefaults.standard.double(forKey: playbackRateKey)
        let playbackRate = (savedRate == 0) ? 1.0 : savedRate
        // 读取此视频的播放进度
        let startTime = UserDefaults.standard.double(forKey: progressKey)

        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                html, body, #player { width: 100%; height: 100%; margin: 0; padding: 0; overflow: hidden; background-color: #000; }
            </style>
        </head>
        <body>
            <div id="player"></div>
            <script>
                const savedPlaybackRate = \(playbackRate);
                const startTime = \(startTime);
                var player;
                var progressSaveInterval; // 用于持有计时器ID

                function onYouTubeIframeAPIReady() {
                    player = new YT.Player('player', {
                        videoId: '\(videoID)',
                        playerVars: {
                            'playsinline': 1, 'autoplay': 1, 'rel': 0, 'controls': 1,
                            'enablejsapi': 1, 'modestbranding': 1,
                            'cc_lang_pref': 'zh-Hans'
                            // 移除了 'start' 参数，改用更可靠的 seekTo 方法
                        },
                        events: {
                            'onReady': onPlayerReady,
                            'onPlaybackRateChange': onPlaybackRateChange,
                            'onStateChange': onPlayerStateChange // 关键：添加状态变化监听
                        }
                    });
                }

                function onPlayerReady(event) {
                    event.target.setPlaybackRate(savedPlaybackRate);
                    
                    // 关键修复：使用 seekTo 强制跳转到指定时间，比 start 参数更可靠
                    event.target.seekTo(startTime, true);
                    event.target.playVideo();
                    
                    // 清理旧的计时器（以防万一）
                    if (progressSaveInterval) {
                        clearInterval(progressSaveInterval);
                    }
                    
                    // 启动一个计时器，每3秒保存一次进度作为备份
                    progressSaveInterval = setInterval(saveProgress, 3000);
                }

                function onPlaybackRateChange(event) {
                    window.webkit?.messageHandlers?.playbackRateHandler?.postMessage(event.data);
                }

                // 关键：监听播放状态变化
                function onPlayerStateChange(event) {
                    // YT.PlayerState.PAUSED = 2 (暂停)
                    // YT.PlayerState.ENDED = 0 (结束)
                    if (event.data == 2 || event.data == 0) {
                        saveProgress(); // 在暂停或结束时立即保存进度
                    }
                }

                // 抽离出保存进度的函数，方便复用
                function saveProgress() {
                    if (player && typeof player.getCurrentTime === 'function') {
                        const currentTime = player.getCurrentTime();
                        if (currentTime > 0) {
                            window.webkit?.messageHandlers?.progressHandler?.postMessage(currentTime);
                        }
                    }
                }

                var tag = document.createElement('script');
                tag.src = "https://www.youtube.com/iframe_api";
                var firstScriptTag = document.getElementsByTagName('script')[0];
                firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
            </script>
        </body>
        </html>
        """
        webView.loadHTMLString(htmlString, baseURL: URL(string: "https://www.youtube.com"))
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 留空
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, playbackRateKey: playbackRateKey, progressKey: progressKey)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: YouTubePlayerView
        let playbackRateKey: String
        let progressKey: String

        init(_ parent: YouTubePlayerView, playbackRateKey: String, progressKey: String) {
            self.parent = parent
            self.playbackRateKey = playbackRateKey
            self.progressKey = progressKey
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "playbackRateHandler":
                if let rate = message.body as? Double {
                    UserDefaults.standard.set(rate, forKey: self.playbackRateKey)
                }
            case "progressHandler":
                if let progress = message.body as? Double, progress > 0 {
                    // 接收到 JS 发来的进度并保存
                    UserDefaults.standard.set(progress, forKey: self.progressKey)
                }
            default:
                break
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView failed navigation: \(error.localizedDescription)")
        }
    }
}
