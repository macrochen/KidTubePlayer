import Foundation

enum YouTubeCaptionServiceError: Error, LocalizedError {
    case apiKeyNotSet
    case invalidVideoID
    case noEnglishCaptionsFound
    case captionDownloadFailed(Error)
    case captionParsingFailed(Error)
    case networkError(Error)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .apiKeyNotSet: return "YouTube API Key 未设置。请在设置中填写。"
        case .invalidVideoID: return "无效的视频ID。"
        case .noEnglishCaptionsFound: return "未找到该视频的英文字幕。"
        case .captionDownloadFailed(let error): return "字幕下载失败: \(error.localizedDescription)"
        case .captionParsingFailed(let error): return "字幕解析失败: \(error.localizedDescription)"
        case .networkError(let error): return "网络错误: \(error.localizedDescription)"
        case .unknownError: return "发生未知错误。"
        }
    }
}

class YouTubeCaptionService {
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }

    /// 获取指定视频ID的英文字幕文本
    /// - Parameter videoID: YouTube视频ID
    /// - Returns: 字幕文本数组，每个元素包含时间戳和文本
    func fetchEnglishCaptions(for videoID: String) async throws -> [(time: Double, text: String)] {
        guard let apiKey = UserSettings.youtubeAPIKey, !apiKey.isEmpty else {
            throw YouTubeCaptionServiceError.apiKeyNotSet
        }
        
        guard !videoID.isEmpty else {
            throw YouTubeCaptionServiceError.invalidVideoID
        }
        
        // 1. 获取字幕列表
        let captionsListURLString = "https://www.googleapis.com/youtube/v3/captions?part=snippet&videoId=\(videoID)&key=\(apiKey)"
        guard let captionsListURL = URL(string: captionsListURLString) else {
            throw YouTubeCaptionServiceError.invalidVideoID
        }
        
        let (data, response) = try await session.data(from: captionsListURL)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw YouTubeCaptionServiceError.networkError(URLError(.badServerResponse))
        }
        
        let captionsListResponse = try JSONDecoder().decode(CaptionsListResponse.self, from: data)
        
        guard let englishCaption = captionsListResponse.items.first(where: { $0.snippet.language == "en" || $0.snippet.language == "en-US" }) else {
            throw YouTubeCaptionServiceError.noEnglishCaptionsFound
        }
        
        // 2. 下载字幕内容
        guard let captionDownloadURL = URL(string: englishCaption.snippet.trackKind == "asr" ? "https://www.youtube.com/api/timedtext?v=\(videoID)&lang=\(englishCaption.snippet.language)&fmt=srv1" : englishCaption.snippet.baseUrl) else {
            throw YouTubeCaptionServiceError.captionDownloadFailed(URLError(.badURL))
        }
        
        let (captionData, _) = try await session.data(from: captionDownloadURL)
        
        // 3. 解析字幕内容 (假设为WebVTT格式，如果YouTube返回XML，需要调整解析逻辑)
        guard let captionString = String(data: captionData, encoding: .utf8) else {
            throw YouTubeCaptionServiceError.captionParsingFailed(URLError(.cannotDecodeContentData))
        }
        
        return parseWebVTT(captionString)
    }
    
    // 简单的WebVTT解析器
    private func parseWebVTT(_ vttString: String) -> [(time: Double, text: String)] {
        var captions: [(time: Double, text: String)] = []
        let lines = vttString.components(separatedBy: .newlines)
        var currentText = ""
        var currentTime: Double = 0.0
        
        for line in lines {
            if line.contains("-->") {
                // This line contains time information
                let components = line.components(separatedBy: " --> ")
                if components.count == 2 {
                    let startTimeString = components[0]
                    // Convert HH:MM:SS.mmm to seconds
                    let timeComponents = startTimeString.components(separatedBy: ":")
                    if timeComponents.count == 3, let hours = Double(timeComponents[0]), let minutes = Double(timeComponents[1]), let seconds = Double(timeComponents[2]) {
                        currentTime = hours * 3600 + minutes * 60 + seconds
                    }
                }
            } else if !line.isEmpty && !line.starts(with: "WEBVTT") && !line.starts(with: "NOTE") {
                // This line is caption text
                currentText += line.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                if !currentText.isEmpty {
                    captions.append((time: currentTime, text: currentText))
                    currentText = ""
                }
            }
        }
        return captions
    }
}

// MARK: - Helper Structs for YouTube Data API Response

struct CaptionsListResponse: Decodable {
    let items: [CaptionItem]
}

struct CaptionItem: Decodable {
    let id: String
    let snippet: CaptionSnippet
}

struct CaptionSnippet: Decodable {
    let videoId: String
    let language: String
    let trackKind: String // e.g., "asr" for automatic speech recognition
    let baseUrl: String
}
