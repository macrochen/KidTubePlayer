import SwiftUI
import SwiftData

struct VocabularyView: View {
    let video: Video
    @Environment(\.modelContext) private var modelContext
    
    @Query var videoVocabularies: [VideoVocabulary]
    
    init(video: Video) {
        self.video = video
        let videoIdToFilter = video.id // Capture the video ID as a local constant
        _videoVocabularies = Query(filter: #Predicate { $0.videoID == videoIdToFilter }, sort: \VideoVocabulary.originalSentence)
    }
    
    var body: some View {
        List {
            ForEach(videoVocabularies) { videoVocab in
                VStack(alignment: .leading, spacing: 8) {
                    Text(videoVocab.vocabularyWord.word)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(videoVocab.vocabularyWord.definition)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text("Original: " + videoVocab.originalSentence)
                        .font(.subheadline)
                    Text("Translated: " + videoVocab.translatedSentence)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Difficulty Picker
                    Picker("Difficulty", selection: Binding(get: { videoVocab.vocabularyWord.difficulty }, set: { newValue in
                        videoVocab.vocabularyWord.difficulty = newValue
                        try? modelContext.save()
                    })) {
                        Text("简单").tag(0)
                        Text("容易").tag(1)
                        Text("一般").tag(2)
                        Text("困难").tag(3)
                        Text("太难").tag(4)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("生词本 - \(video.title)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VocabularyView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleVideo = Video(id: "sampleID", platform: .youtube, title: "Sample Video Title", author: "Sample Author", viewCount: 1000, uploadDate: Date(), authorAvatarURL: nil, thumbnailURL: nil)
        
        // Create a temporary ModelContainer for preview
        let container: ModelContainer
        do {
            let schema = Schema([Video.self, PlaybackRecord.self, VocabularyWord.self, VideoVocabulary.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true) // Use in-memory for preview
            container = try ModelContainer(for: schema, configurations: [config])
            
            // Add some sample data for preview
            let word1 = VocabularyWord(word: "example", definition: "例子")
            let word2 = VocabularyWord(word: "test", definition: "测试")
            
            let videoVocab1 = VideoVocabulary(videoID: sampleVideo.id, originalSentence: "This is an example sentence.", translatedSentence: "这是一个例句。", vocabularyWord: word1, video: sampleVideo)
            let videoVocab2 = VideoVocabulary(videoID: sampleVideo.id, originalSentence: "This is a test sentence.", translatedSentence: "这是一个测试句。", vocabularyWord: word2, video: sampleVideo)
            
            container.mainContext.insert(word1)
            container.mainContext.insert(word2)
            container.mainContext.insert(sampleVideo)
            container.mainContext.insert(videoVocab1)
            container.mainContext.insert(videoVocab2)
            
        } catch {
            fatalError("Failed to create ModelContainer for preview: \(error)")
        }
        
        return NavigationView {
            VocabularyView(video: sampleVideo)
        }
        .modelContainer(container)
    }
}
