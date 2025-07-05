import Foundation
import SwiftData

@Model
final class VocabularyWord {
    @Attribute(.unique) var word: String // 单词本身，唯一标识
    var definition: String // Gemini API 提供的中文释义
    var difficulty: Int // 难度标注 (0: 简单, 1: 容易, 2: 一般, 3: 困难, 4: 太难)
    var addedDate: Date // 添加到总生词本的日期

    // 与 VideoVocabulary 的关系：一个单词可以在多个视频中出现
    @Relationship(deleteRule: .cascade, inverse: \VideoVocabulary.vocabularyWord)
    var videoOccurrences: [VideoVocabulary]?

    init(word: String, definition: String, difficulty: Int = 2, addedDate: Date = Date()) {
        self.word = word
        self.definition = definition
        self.difficulty = difficulty
        self.addedDate = addedDate
    }
}