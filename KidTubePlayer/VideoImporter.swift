
import Foundation

class VideoImporter: ObservableObject {
    @Published var videos: [Video] = []
    private let storageURL: URL

    init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageURL = documentsDirectory.appendingPathComponent("videos.json")
        loadVideos()
    }

    private func loadVideos() {
        do {
            let data = try Data(contentsOf: storageURL)
            videos = try JSONDecoder().decode([Video].self, from: data)
        } catch {
            print("Could not load videos, starting fresh: \(error)")
            videos = []
        }
    }

    private func saveVideos() {
        do {
            let data = try JSONEncoder().encode(videos)
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
            let importedVideos = try JSONDecoder().decode([Video].self, from: data)
            DispatchQueue.main.async {
                let existingIds = Set(self.videos.map { $0.id })
                let newVideos = importedVideos.filter { !existingIds.contains($0.id) }
                self.videos.append(contentsOf: newVideos)
                self.saveVideos()
            }
        } catch {
            print("Error importing videos: \(error)")
        }
    }
    
    func deleteVideos(with ids: Set<String>) {
        videos.removeAll { ids.contains($0.id) }
        saveVideos()
    }
}
