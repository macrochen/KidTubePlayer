import Foundation

/// 提供静态的视频列表数据
struct VideoProvider {
    
    /// 一个精选的视频列表
    static let allVideos: [Video] = [
        Video(
            id: "_U-7oN5AdmU",
            title: "Minecraft Speedrunner VS $100,000 Bounty Hunter",
            author: "Dream",
            viewCount: 158349012,
            uploadDate: Calendar.current.date(byAdding: .hour, value: -11, to: Date())!,
            // 关键：为新增的 authorAvatarURL 属性提供一个值
            authorAvatarURL: URL(string: "https://yt3.ggpht.com/ytc/AIdro_k-vC2rcK2j_b4Y_Z3-a_y-M-s_z-z_Z-z_Z-z=s88-c-k-c0x00ffffff-no-rj")
        )
    ]
}
