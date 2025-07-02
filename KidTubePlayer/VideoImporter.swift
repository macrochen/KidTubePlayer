import Foundation
import SwiftUI

// 定义一个结构体来封装导入操作的结果
struct ImportResult: Identifiable, Equatable {
    let id = UUID()
    let successCount: Int
    let duplicateCount: Int
    let totalInFile: Int
    let errorMessage: String?
}

class VideoImporter: ObservableObject {
    @Published var videos: [Video] = []
    @Published var importResult: ImportResult?

    private let storageURL: URL

    init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageURL = documentsDirectory.appendingPathComponent("videos.json")
        loadVideos()
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

    private func loadVideos() {
        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            // 加载本地文件时也使用自定义的日期格式
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            videos = try decoder.decode([Video].self, from: data)
        } catch {
            print("Could not load videos, starting fresh: \(error)")
            videos = []
        }
    }

    private func saveVideos() {
        do {
            let encoder = JSONEncoder()
            // 保存时也使用同样的日期格式
            encoder.dateEncodingStrategy = .formatted(dateFormatter)
            let data = try encoder.encode(videos)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Error saving videos: \(error)")
        }
    }

    func importVideos(from url: URL) {
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

            let importedVideos = try decoder.decode([Video].self, from: data)
            
            DispatchQueue.main.async {
                let existingIds = Set(self.videos.map { $0.id })
                
                let newVideos = importedVideos.filter { !existingIds.contains($0.id) }
                let newVideosCount = newVideos.count
                
                self.videos.append(contentsOf: newVideos)
                
                if newVideosCount > 0 {
                    self.saveVideos()
                }

                // 创建一个成功的导入结果
                self.importResult = ImportResult(
                    successCount: newVideosCount,
                    duplicateCount: importedVideos.count - newVideosCount,
                    totalInFile: importedVideos.count,
                    errorMessage: nil
                )
            }
        } catch {
            // 如果发生任何错误，创建一个失败的导入结果
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
    
    func deleteVideos(with ids: Set<String>) {
        videos.removeAll { ids.contains($0.id) }
        saveVideos()
    }
}
