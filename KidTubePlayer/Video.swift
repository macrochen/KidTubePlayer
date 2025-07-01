import Foundation

/// Represents a single video item in the KidTubePlayer app.
struct Video: Identifiable, Codable, Hashable {
    /// The unique YouTube video ID.
    let id: String
    
    /// The custom title for the video.
    let title: String
    
    /// The URL for the video's thumbnail image.
    var thumbnailURL: URL? {
        return URL(string: "https://img.youtube.com/vi/\(id)/hqdefault.jpg")
    }
    
    // A more detailed description for the video card.
}
