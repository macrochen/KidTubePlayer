import Foundation
import SwiftUI
import SwiftData

// 定义一个结构体来封装导入操作的结果
struct ImportResult: Identifiable, Equatable {
    let id = UUID()
    let successCount: Int
    let duplicateCount: Int
    let totalInFile: Int
    let errorMessage: String?
}

// 用于从 JSON 解码的临时结构体
struct VideoImportData: Decodable {
    let id: String
    let platform: Platform? // Make it optional for backward compatibility
    let title: String
    let author: String?
    let viewCount: Int?
    let uploadDate: Date?
    let authorAvatarURL: URL?
    let thumbnailURL: URL?
    let fullSubtitleText: String? // 新增：字幕文本
    let duration: TimeInterval? // 新增：视频时长

    enum CodingKeys: String, CodingKey {
        case id, platform, title, author, viewCount, uploadDate, authorAvatarURL, thumbnailURL, fullSubtitleText, duration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        platform = try container.decodeIfPresent(Platform.self, forKey: .platform)
        title = try container.decode(String.self, forKey: .title)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount)
        uploadDate = try container.decodeIfPresent(Date.self, forKey: .uploadDate)
        authorAvatarURL = try container.decodeIfPresent(URL.self, forKey: .authorAvatarURL)
        thumbnailURL = try container.decodeIfPresent(URL.self, forKey: .thumbnailURL)
        fullSubtitleText = try container.decodeIfPresent(String.self, forKey: .fullSubtitleText)
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
    }
}

class VideoImporter: ObservableObject {
    @Published var importResult: ImportResult?

    init() {
        // No longer loading from JSON file
    }

    // 创建一个自定义的日期格式化器
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        // 关键：精确匹配插件生成的格式 "年-月-日T时:分:秒.毫秒Z"
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX") // 保证在任何设备上都一致
        return formatter
    }

    func importVideos(from url: URL, modelContext: ModelContext) {
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            let decoder = JSONDecoder()
            // 关键：告诉解码器使用我们自定义的日期格式化器
            decoder.dateDecodingStrategy = .formatted(dateFormatter)

            let importedVideosData = try decoder.decode([VideoImportData].self, from: data)
            
            var successCount = 0
            var duplicateCount = 0
            
            for videoData in importedVideosData {
                let videoIDToSearch = videoData.id // Capture the ID as a local constant
                let descriptor = FetchDescriptor<Video>(predicate: #Predicate { $0.id == videoIDToSearch })
                let existingVideos = try modelContext.fetch(descriptor)
                
                if existingVideos.isEmpty {
                    // Create a SwiftData Video object from VideoImportData
                    let newVideo = Video(
                        id: videoData.id,
                        platform: videoData.platform ?? .youtube, // Default to .youtube if not present
                        title: videoData.title,
                        author: videoData.author ?? "未知作者",
                        viewCount: videoData.viewCount ?? 0,
                        uploadDate: videoData.uploadDate ?? Date(),
                        authorAvatarURL: videoData.authorAvatarURL,
                        thumbnailURL: videoData.thumbnailURL,
                        fullSubtitleText: videoData.fullSubtitleText, // Pass fullSubtitleText
                        duration: videoData.duration // Pass duration
                    )
                    modelContext.insert(newVideo)
                    successCount += 1
                } else {
                    duplicateCount += 1
                }
            }
            try modelContext.save() // Explicitly save changes after import
            
            DispatchQueue.main.async {
                self.importResult = ImportResult(
                    successCount: successCount,
                    duplicateCount: duplicateCount,
                    totalInFile: importedVideosData.count,
                    errorMessage: nil
                )
            }
        } catch {
            print("ERROR: Video import failed: \(error.localizedDescription)")
            // If any error occurs during import or save
            DispatchQueue.main.async {
                self.importResult = ImportResult(
                    successCount: 0,
                    duplicateCount: 0,
                    totalInFile: 0,
                    errorMessage: "导入失败。请检查文件格式是否正确。\n\n错误详情: \(error.localizedDescription)"
                )
            }
        }
    }
    
    func deleteVideos(with ids: Set<String>, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Video>(predicate: #Predicate { ids.contains($0.id) })
        do {
            let videosToDelete = try modelContext.fetch(descriptor)
            for video in videosToDelete {
                modelContext.delete(video)
            }
        } catch {
            print("Error deleting videos: \(error)")
        }
    }
}
