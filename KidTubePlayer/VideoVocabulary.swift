import Foundation
import SwiftData

@Model
final class VideoVocabulary {
    var videoID: String // 关联的视频ID
    var originalSentence: String // 视频中出现的原始英文例句
    var translatedSentence: String // 例句的中文翻译

    // 与 VocabularyWord 的关系：多对一，多个 VideoVocabulary 实例指向同一个 VocabularyWord
    var vocabularyWord: VocabularyWord // 关联的 VocabularyWord 对象

    // 与 Video 的关系：多对一，多个 VideoVocabulary 实例指向同一个 Video
    var video: Video // 关联的 Video 对象

    init(videoID: String, originalSentence: String, translatedSentence: String, vocabularyWord: VocabularyWord, video: Video) {
        self.videoID = videoID
        self.originalSentence = originalSentence
        self.translatedSentence = translatedSentence
        self.vocabularyWord = vocabularyWord
        self.video = video
    }
}