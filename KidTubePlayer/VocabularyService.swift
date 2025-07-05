import Foundation
import SwiftData

enum VocabularyServiceError: Error, LocalizedError {
    case videoNotFound
    case noCaptionsAvailable
    case wordProcessingFailed
    case geminiAPIFailed(Error)
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .videoNotFound: return "未找到对应的视频信息。"
        case .noCaptionsAvailable: return "该视频没有可用的英文字幕。"
        case .wordProcessingFailed: return "生词处理失败。"
        case .geminiAPIFailed(let error): return "Gemini API 调用失败: \(error.localizedDescription)"
        case .saveFailed(let error): return "生词保存失败: \(error.localizedDescription)"
        }
    }
}

enum VocabularyGenerationStatus: Equatable {
    case idle
    case checkingExistingData
    case fetchingCaptions
    case processingText
    case fetchingDefinitionsAndExamples
    case savingToDatabase
    case completed
    case failed(String)
}

class VocabularyService: ObservableObject {
    private let captionService: YouTubeCaptionService
    private let geminiService: GeminiService
    
    @Published var status: VocabularyGenerationStatus = .idle
    @Published var errorMessage: String? = nil
    
    init(captionService: YouTubeCaptionService = YouTubeCaptionService(),
         geminiService: GeminiService = GeminiService()) {
        self.captionService = captionService
        self.geminiService = geminiService
    }
    
    /// 为指定视频生成生词本
    /// - Parameters:
    ///   - video: 视频对象
    ///   - modelContext: SwiftData 的 ModelContext
    func generateVocabulary(for video: Video, modelContext: ModelContext) async {
        DispatchQueue.main.async {
            self.status = .checkingExistingData
            self.errorMessage = nil
        }
        print("DEBUG: VocabularyService - Starting generation for video: \(video.title)")

        do {
            // 1. 检查是否已存在该视频的生词数据
            let videoId = video.id
            let descriptor = FetchDescriptor<VideoVocabulary>(predicate: #Predicate { $0.videoID == videoId })
            let existingVideoVocabularies = try modelContext.fetch(descriptor)
            if !existingVideoVocabularies.isEmpty {
                print("DEBUG: VocabularyService - Vocabulary for video \(video.title) already exists. Skipping generation.")
                DispatchQueue.main.async {
                    self.status = .completed
                }
                return // 已经生成过，直接返回
            }
            
            // 2. 获取字幕
            DispatchQueue.main.async { self.status = .fetchingCaptions }
            print("DEBUG: VocabularyService - Fetching captions...")
            let captions = try await captionService.fetchEnglishCaptions(for: video.id)
            guard !captions.isEmpty else {
                throw VocabularyServiceError.noCaptionsAvailable
            }
            print("DEBUG: VocabularyService - Captions fetched. Total lines: \(captions.count)")
            
            let fullSubtitleText = captions.map { $0.text }.joined(separator: " ")
            
            // 3. 文本处理：分词、小写化、去除标点、过滤停用词、去重
            DispatchQueue.main.async { self.status = .processingText }
            print("DEBUG: VocabularyService - Processing text...")
            let words = processSubtitleText(fullSubtitleText)
            guard !words.isEmpty else {
                throw VocabularyServiceError.wordProcessingFailed
            }
            print("DEBUG: VocabularyService - Text processed. Unique words: \(words.count)")
            
            // 4. 批量获取释义和翻译
            DispatchQueue.main.async { self.status = .fetchingDefinitionsAndExamples }
            print("DEBUG: VocabularyService - Fetching definitions and examples from Gemini...")
            let geminiWordData = try await geminiService.fetchDefinitionsAndExamples(words: words, subtitleText: fullSubtitleText)
            print("DEBUG: VocabularyService - Definitions and examples fetched. Total: \(geminiWordData.count)")
            
            // 5. 保存到 SwiftData
            DispatchQueue.main.async { self.status = .savingToDatabase }
            print("DEBUG: VocabularyService - Saving to database...")
            for data in geminiWordData {
                // 查找或创建 VocabularyWord
                let currentWord = data.word
                let wordDescriptor = FetchDescriptor<VocabularyWord>(predicate: #Predicate { $0.word == currentWord })
                var vocabularyWord: VocabularyWord
                if let existingWord = try modelContext.fetch(wordDescriptor).first {
                    vocabularyWord = existingWord
                } else {
                    vocabularyWord = VocabularyWord(word: data.word, definition: data.definition)
                    modelContext.insert(vocabularyWord)
                }
                
                // 创建 VideoVocabulary
                let videoVocabulary = VideoVocabulary(
                    videoID: video.id,
                    originalSentence: data.originalSentence,
                    translatedSentence: data.translatedSentence,
                    vocabularyWord: vocabularyWord,
                    video: video
                )
                modelContext.insert(videoVocabulary)
            }
            
            try modelContext.save()
            print("DEBUG: VocabularyService - Saved to database successfully.")
            
            DispatchQueue.main.async {
                self.status = .completed
            }
        } catch {
            print("ERROR: VocabularyService - Generation failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.status = .failed(error.localizedDescription)
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func processSubtitleText(_ text: String) -> [String] {
        let stopWords = UserSettings.stopWords.map { $0.lowercased() }
        
        let cleanedText = text.lowercased()
                                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                                .filter { !$0.isEmpty && !$0.allSatisfy({ $0.isNumber }) }
        
        let filteredWords = cleanedText.filter { !stopWords.contains($0) }
        
        return Array(Set(filteredWords)).sorted() // 去重并排序
    }
}
