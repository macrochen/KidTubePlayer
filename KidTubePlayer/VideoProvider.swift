import Foundation

/// 提供静态的视频列表数据
struct VideoProvider {
    
    /// 一个精选的视频列表
    static let allVideos: [Video] = [
        Video(
            id: "_U-7oN5AdmU",
            title: "Minecraft Speedrunner VS $100,000 Bounty Hunter",
            // --- 补充新数据 ---
            author: "Dream",
            viewCount: 158349012, // 示例观看次数
            // 创建一个表示“11小时前”的日期
            uploadDate: Calendar.current.date(byAdding: .hour, value: -11, to: Date())!
        )
    ]
}
