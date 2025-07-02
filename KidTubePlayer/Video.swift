import Foundation

enum Platform: String, Codable, Hashable {
    case youtube
    case bilibili
}

// 关键修复：将 Video 恢复为 struct，以确保与 SwiftUI 导航系统的最佳兼容性
struct Video: Identifiable, Codable, Hashable {
    let id: String
    let platform: Platform
    let title: String
    let author: String
    let viewCount: Int
    let uploadDate: Date
    let authorAvatarURL: URL?
    let thumbnailURL: URL?

    // --- Codable 协议实现 ---
    // 我们仍然需要一个自定义的解码器，以兼容不包含新字段（如platform）的旧版JSON文件
    enum CodingKeys: String, CodingKey {
        case id, platform, title, author, viewCount, uploadDate, authorAvatarURL, thumbnailURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        // 解码 platform，如果 JSON 中没有，则默认为 youtube 以兼容旧数据
        platform = try container.decodeIfPresent(Platform.self, forKey: .platform) ?? .youtube
        title = try container.decode(String.self, forKey: .title)
        
        author = try container.decodeIfPresent(String.self, forKey: .author) ?? "未知作者"
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount) ?? 0
        uploadDate = try container.decodeIfPresent(Date.self, forKey: .uploadDate) ?? Date()
        authorAvatarURL = try container.decodeIfPresent(URL.self, forKey: .authorAvatarURL)
        thumbnailURL = try container.decodeIfPresent(URL.self, forKey: .thumbnailURL)
    }

    // 因为我们自定义了上面的解码器，所以需要手动把这个标准的构造函数也加上
    // 这样像 VideoProvider 这样的地方才能继续正常创建 Video 实例
    init(id: String, platform: Platform, title: String, author: String, viewCount: Int, uploadDate: Date, authorAvatarURL: URL?, thumbnailURL: URL?) {
        self.id = id
        self.platform = platform
        self.title = title
        self.author = author
        self.viewCount = viewCount
        self.uploadDate = uploadDate
        self.authorAvatarURL = authorAvatarURL
        self.thumbnailURL = thumbnailURL
    }
}
