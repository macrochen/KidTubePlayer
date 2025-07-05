import Foundation
import SwiftData

enum Platform: String, Codable, Hashable {
    case youtube
    case bilibili
}

@Model
final class Video {
    @Attribute(.unique) var id: String
    var platform: Platform
    var title: String
    var author: String
    var viewCount: Int
    var uploadDate: Date
    var authorAvatarURL: URL?
    var thumbnailURL: URL?
    var fullSubtitleText: String?

    init(id: String, platform: Platform, title: String, author: String, viewCount: Int, uploadDate: Date, authorAvatarURL: URL?, thumbnailURL: URL?, fullSubtitleText: String? = nil) {
        self.id = id
        self.platform = platform
        self.title = title
        self.author = author
        self.viewCount = viewCount
        self.uploadDate = uploadDate
        self.authorAvatarURL = authorAvatarURL
        self.thumbnailURL = thumbnailURL
        self.fullSubtitleText = fullSubtitleText
    }

    

    static let youtubePlatform: Platform = .youtube
}
