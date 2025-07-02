import Foundation

/// 提供静态的视频列表数据
struct VideoProvider {
    
    /// 一个精选的视频列表，现在包含两个平台的视频
    static let allVideos: [Video] = [
        Video(
            id: "_U-7oN5AdmU",
            platform: .youtube, // 指定平台
            title: "Minecraft Speedrunner VS $100,000 Bounty Hunter",
            author: "Dream",
            viewCount: 158349012,
            uploadDate: Calendar.current.date(byAdding: .hour, value: -11, to: Date())!,
            authorAvatarURL: URL(string: "https://yt3.ggpht.com/ytc/AIdro_k-vC2rcK2j_b4Y_Z3-a_y-M-s_z-z_Z-z_Z-z=s88-c-k-c0x00ffffff-no-rj"),
            thumbnailURL: URL(string: "https://i.ytimg.com/vi/_U-7oN5AdmU/hqdefault.jpg")
        ),
        Video(
            id: "BV19K421L7V1",
            platform: .bilibili, // 指定平台
            title: "【IGN】《黑神话：悟空》13分钟实机试玩",
            author: "IGN中国",
            viewCount: 2450000,
            uploadDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            authorAvatarURL: URL(string: "https://i1.hdslb.com/bfs/face/47f5984539a23f4333b04153a63445a5e3394a59.jpg"),
            thumbnailURL: URL(string: "https://i0.hdslb.com/bfs/archive/f7c9ce3a267a702766346b02674a21e777f59797.jpg")
        )
    ]
}
