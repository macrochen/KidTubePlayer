import Foundation

/// 代表一个视频项目
/// 关键修复：将 Video 从 struct 改为 class。
/// 这是一个更根本的改变，旨在通过改变数据类型（从值类型到引用类型）来彻底解决顽固的编译器歧义问题。
final class Video: Identifiable, Codable, Hashable {
    
    // --- 属性 ---
    let id: String
    let title: String
    let author: String
    let viewCount: Int
    let uploadDate: Date
    let authorAvatarURL: URL? // 新增：作者头像的 URL

    var thumbnailURL: URL? {
        return URL(string: "https://img.youtube.com/vi/\(id)/hqdefault.jpg")
    }

    // --- 构造函数 ---
    // 用于在代码中（如 VideoProvider）创建实例
    init(id: String, title: String, author: String, viewCount: Int, uploadDate: Date, authorAvatarURL: URL?) {
        self.id = id
        self.title = title
        self.author = author
        self.viewCount = viewCount
        self.uploadDate = uploadDate
        self.authorAvatarURL = authorAvatarURL
    }
    
    // --- Codable 协议实现 ---
    enum CodingKeys: String, CodingKey {
        case id, title, author, viewCount, uploadDate, authorAvatarURL
    }

    // 因为这是一个 class，我们需要一个 "convenience" 初始化方法来满足 Decodable
    convenience required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let id = try container.decode(String.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        
        let author = try container.decodeIfPresent(String.self, forKey: .author) ?? "未知作者"
        let viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount) ?? 0
        let uploadDate = try container.decodeIfPresent(Date.self, forKey: .uploadDate) ?? Date()
        let authorAvatarURL = try container.decodeIfPresent(URL.self, forKey: .authorAvatarURL)
        
        // 调用指定的构造函数
        self.init(id: id, title: title, author: author, viewCount: viewCount, uploadDate: uploadDate, authorAvatarURL: authorAvatarURL)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(author, forKey: .author)
        try container.encode(viewCount, forKey: .viewCount)
        try container.encode(uploadDate, forKey: .uploadDate)
        try container.encodeIfPresent(authorAvatarURL, forKey: .authorAvatarURL)
    }

    // --- Hashable & Equatable 协议实现 ---
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Video, rhs: Video) -> Bool {
        return lhs.id == rhs.id
    }
}
