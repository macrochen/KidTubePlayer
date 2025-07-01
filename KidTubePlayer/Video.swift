import Foundation

/// 代表一个视频项目
struct Video: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let author: String
    let viewCount: Int
    let uploadDate: Date
    
    var thumbnailURL: URL? {
        return URL(string: "https://img.youtube.com/vi/\(id)/hqdefault.jpg")
    }

    // 定义 JSON 的键，方便解码时使用
    enum CodingKeys: String, CodingKey {
        case id, title, author, viewCount, uploadDate
    }

    // 自定义的解码方法，让模型能处理缺失的字段
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // id 和 title 是必须的字段，如果缺失则解码失败
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        
        // author, viewCount, uploadDate 是新字段，可能在旧的JSON文件中不存在
        // 我们使用 `decodeIfPresent` 尝试解码，如果字段不存在 (nil)，就提供一个默认值
        author = try container.decodeIfPresent(String.self, forKey: .author) ?? "未知作者"
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount) ?? 0
        uploadDate = try container.decodeIfPresent(Date.self, forKey: .uploadDate) ?? Date() // 如果没有日期，就默认为当前时间
    }
    
    // 因为我们自定义了上面的 init(from:) 解码器，
    // Swift 不再自动提供默认的构造函数，所以我们需要手动把它加回来，
    // 这样像 VideoProvider 这样的地方才能继续正常创建 Video 实例。
    init(id: String, title: String, author: String, viewCount: Int, uploadDate: Date) {
        self.id = id
        self.title = title
        self.author = author
        self.viewCount = viewCount
        self.uploadDate = uploadDate
    }
}
