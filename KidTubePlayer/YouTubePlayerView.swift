import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {

    let videoID: String
    let videoTitle: String // 新增 videoTitle，用于记录历史
    
    private let playbackRateKey = "youtubePlaybackRate"
    private var progressKey: String { "progress-\(videoID)" }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let contentController = configuration.userContentController
        contentController.add(context.coordinator, name: "playbackRateHandler")
        contentController.add(context.coordinator, name: "progressHandler")
        contentController.add(context.coordinator, name: "playbackSessionHandler") // 新增：用于处理播放会话

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let savedRate = UserDefaults.standard.double(forKey: playbackRateKey)
        let playbackRate = (savedRate == 0) ? 1.0 : savedRate
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
                var progressSaveInterval;

                function onYouTubeIframeAPIReady() {
                    player = new YT.Player('player', {
                        videoId: '\(videoID)',
                        playerVars: {
                            'playsinline': 1, 'autoplay': 1, 'rel': 0, 'controls': 1,
                            'enablejsapi': 1, 'modestbranding': 1,
                            'cc_lang_pref': 'zh-Hans'
                        },
                        events: {
                            'onReady': onPlayerReady,
                            'onPlaybackRateChange': onPlaybackRateChange,
                            'onStateChange': onPlayerStateChange
                        }
                    });
                }

                function onPlayerReady(event) {
                    event.target.setPlaybackRate(savedPlaybackRate);
                    event.target.seekTo(startTime, true);
                    event.target.playVideo();
                    if (progressSaveInterval) clearInterval(progressSaveInterval);
                    progressSaveInterval = setInterval(saveProgress, 3000);
                }

                function onPlaybackRateChange(event) {
                    window.webkit?.messageHandlers?.playbackRateHandler?.postMessage(event.data);
                }

                function onPlayerStateChange(event) {
                    // YT.PlayerState.PLAYING = 1
                    // YT.PlayerState.PAUSED = 2
                    // YT.PlayerState.ENDED = 0
                    if (event.data == 1) { // Playing
                        window.webkit.messageHandlers.playbackSessionHandler.postMessage("start");
                    } else if (event.data == 2 || event.data == 0) { // Paused or Ended
                        saveProgress();
                        window.webkit.messageHandlers.playbackSessionHandler.postMessage("end");
                    }
                }

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

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self, videoID: videoID, videoTitle: videoTitle, playbackRateKey: playbackRateKey, progressKey: progressKey)
    }
    
    // 新增：当视图被销毁时，确保最后的播放记录被保存
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.endPlaybackSession()
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: YouTubePlayerView
        let videoID: String
        let videoTitle: String
        let playbackRateKey: String
        let progressKey: String
        
        private var playbackStartTime: Date?

        init(_ parent: YouTubePlayerView, videoID: String, videoTitle: String, playbackRateKey: String, progressKey: String) {
            self.parent = parent
            self.videoID = videoID
            self.videoTitle = videoTitle
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
                    UserDefaults.standard.set(progress, forKey: self.progressKey)
                }
            case "playbackSessionHandler":
                if let action = message.body as? String {
                    if action == "start" {
                        startPlaybackSession()
                    } else if action == "end" {
                        endPlaybackSession()
                    }
                }
            default:
                break
            }
        }
        
        func startPlaybackSession() {
            if playbackStartTime == nil {
                playbackStartTime = Date()
            }
        }
        
        func endPlaybackSession() {
            guard let startTime = playbackStartTime else { return }
            
            let endTime = Date()
            // 只有当播放时长大于一个很小的值（比如5秒）时才记录，避免意外的短记录
            if endTime.timeIntervalSince(startTime) > 5.0 {
                let record = PlaybackRecord(
                    videoID: self.videoID,
                    videoTitle: self.videoTitle,
                    platform: .youtube,
                    startTime: startTime,
                    endTime: endTime
                )
                PlaybackHistoryManager.shared.addRecord(record)
            }
            // 重置开始时间，为下一次播放做准备
            playbackStartTime = nil
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView failed navigation: \(error.localizedDescription)")
        }
    }
}
