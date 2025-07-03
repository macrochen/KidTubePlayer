
//
//  PlaybackRecord.swift
//  KidTubePlayer
//
//  Created by Gemini on 2025/7/3.
//

import Foundation

/// 描述一次视频播放记录的数据模型
struct PlaybackRecord: Identifiable, Codable {
    /// 每条记录的唯一ID
    let id: UUID
    
    /// 关联的视频ID (YouTube的Video ID或Bilibili的BVID)
    let videoID: String
    
    /// 视频标题，用于在历史记录中直接显示
    let videoTitle: String
    
    /// 视频来源平台
    let platform: Platform
    
    /// 本次播放的开始时间
    let startTime: Date
    
    /// 本次播放的结束时间
    let endTime: Date
    
    /// 经过计算的播放时长（单位：秒）
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    /// 记录所属的日期（方便按天分组）
    var date: Date {
        return Calendar.current.startOfDay(for: startTime)
    }
    
    // 为了遵循Identifiable协议，并让id在解码时自动生成
    // 我们需要自定义解码过程
    enum CodingKeys: String, CodingKey {
        case id, videoID, videoTitle, platform, startTime, endTime
    }
    
    init(id: UUID = UUID(), videoID: String, videoTitle: String, platform: Platform, startTime: Date, endTime: Date) {
        self.id = id
        self.videoID = videoID
        self.videoTitle = videoTitle
        self.platform = platform
        self.startTime = startTime
        self.endTime = endTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // 如果JSON数据中没有id，则自动创建一个新的UUID
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.videoID = try container.decode(String.self, forKey: .videoID)
        self.videoTitle = try container.decode(String.self, forKey: .videoTitle)
        self.platform = try container.decode(Platform.self, forKey: .platform)
        self.startTime = try container.decode(Date.self, forKey: .startTime)
        self.endTime = try container.decode(Date.self, forKey: .endTime)
    }
}

