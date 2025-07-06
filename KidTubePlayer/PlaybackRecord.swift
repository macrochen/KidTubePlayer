
import Foundation
import SwiftData

/// 描述一次视频播放记录的数据模型
@Model
final class PlaybackRecord {
    /// 关联的视频ID (YouTube的Video ID或Bilibili的BVID)
    var videoID: String
    
    /// 视频标题，用于在历史记录中直接显示
    var videoTitle: String
    
    /// 视频来源平台
    var platform: Platform
    
    /// 本次播放的开始时间
    var startTime: Date
    
    /// 本次播放的结束时间
    var endTime: Date
    
    /// 经过计算的播放时长（单位：秒）
    var duration: TimeInterval
    
    
    
    /// 记录所属的日期（方便按天分组）
    var recordDate: Date
    
    init(videoID: String, videoTitle: String, platform: Platform, startTime: Date, endTime: Date) {
        self.videoID = videoID
        self.videoTitle = videoTitle
        self.platform = platform
        self.startTime = startTime
        self.endTime = endTime
        self.duration = endTime.timeIntervalSince(startTime)
        self.recordDate = Calendar.current.startOfDay(for: startTime)
    }
}

