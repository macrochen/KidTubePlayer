### KidTubePlayer - 生词本功能设计文档 (更新)

**文档版本**: V1.3
**创建日期**: 2025年7月4日
**更新日期**: 2025年7月4日
**创建人**: Gemini
**状态**: 草稿

---

#### 1. 引言

为了进一步提升 KidTubePlayer 在儿童英语学习方面的价值，本设计文档提出了“生词本”功能。该功能旨在为孩子提供一个互动式的词汇学习工具，通过视频字幕提取生词，并允许孩子自主标注单词难度，从而构建个性化的生词表。

#### 2. 目标

*   **用户目标**:
    *   为孩子提供一个便捷的途径，在观看视频的同时学习和管理生词。
    *   允许孩子根据自身理解，对单词进行难度标注，实现个性化学习。
    *   为家长提供一个总览孩子词汇学习进度的工具。
    *   允许家长自定义和维护停用词列表，以更精准地筛选生词。
    *   **允许小朋友（非家长模式下）访问和维护生词本及停用词列表，增强自主学习能力。**
*   **技术目标**:
    *   实现与 YouTube Data API 和 Gemini API 的集成，自动化生词提取和释义获取。
    *   优化 Gemini API 调用，支持批量处理，提高效率。
    *   利用 SwiftData 高效持久化生词数据及其关联关系。
    *   设计灵活的数据模型，支持未来扩展（如单词复习、测验等）。

#### 3. 受影响模块与文件

*   **新增文件**:
    *   `VocabularyWord.swift`: SwiftData 模型，用于存储生词数据。
    *   `VideoVocabulary.swift`: SwiftData 模型，用于存储视频与生词的关联，以及视频内例句。
    *   `VocabularyService.swift`: 负责生词的提取、API 调用、数据处理和 SwiftData 存储的业务逻辑层。
    *   `VocabularyView.swift`: 视频播放页面内展示生词本的 SwiftUI 视图。
    *   `MasterVocabularyView.swift`: 展示所有生词的总生词本 SwiftUI 视图。
    *   `APISettingsView.swift`: 用于配置 API Key 的 SwiftUI 视图。
    *   `StopWordsSettingsView.swift`: 用于配置停用词列表的 SwiftUI 视图。
*   **修改文件**:
    *   `KidTubePlayerApp.swift`: 配置新的 SwiftData 模型。
    *   `PlayerView.swift`: 添加“生词本”按钮，并导航到 `VocabularyView`。**生词本按钮的可见性将不再受家长模式限制。**
    *   `VideoListView.swift`: 在家长模式下添加“我的生词本”入口，导航到 `MasterVocabularyView`。同时，新增“API 设置”入口。新增“停用词设置”入口。**“我的生词本”和“停用词设置”入口的可见性将不再受家长模式限制。**
    *   `Video.swift`: 可能需要添加与 `VideoVocabulary` 的关系。
    *   `UserSettings.swift`: 新增，用于安全存储 API Key 和可配置的停用词列表。
    *   `VocabularyService.swift`: 修改为从 `UserSettings` 获取 API Key 和停用词列表，并实现批量 API 调用逻辑。

#### 4. 数据模型设计 (SwiftData)

##### 4.1. `VocabularyWord` 模型

代表一个唯一的生词。

```swift
@Model
final class VocabularyWord {
    @Attribute(.unique) var word: String // 单词本身，唯一标识
    var definition: String // Gemini API 提供的中文释义
    var difficulty: Int // 难度标注 (0: 简单, 1: 容易, 2: 一般, 3: 困难, 4: 太难)
    var addedDate: Date // 添加到总生词本的日期

    // 与 VideoVocabulary 的关系：一个单词可以在多个视频中出现
    @Relationship(inverse: \VideoVocabulary.vocabularyWord)
    var videoOccurrences: [VideoVocabulary]?

    init(word: String, definition: String, difficulty: Int = 2, addedDate: Date = Date()) {
        self.word = word
        self.definition = definition
        self.difficulty = difficulty
        self.addedDate = addedDate
    }
}
```

##### 4.2. `VideoVocabulary` 模型

代表一个视频中出现的生词实例，包含该单词在视频中的具体例句和翻译。

```swift
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
```

##### 4.3. `Video` 模型更新

在 `Video.swift` 中添加与 `VideoVocabulary` 的关系，表示一个视频可以有多个生词。

```swift
// 在 Video.swift 中添加
@Relationship(inverse: \VideoVocabulary.video)
var videoVocabularies: [VideoVocabulary]?
```

#### 5. API 集成

##### 5.1. YouTube Data API (获取字幕)

*   **用途**: 获取指定 `videoID` 的英文字幕文本。
*   **认证**: 需要配置 YouTube Data API Key。
*   **流程**:
    1.  构建 API 请求 URL (e.g., `https://www.googleapis.com/youtube/v3/captions?part=snippet&videoId={videoID}&key={API_KEY}`).
    2.  解析响应，找到英文字幕的 `id`。
    3.  构建字幕下载 URL (e.g., `https://www.googleapis.com/youtube/v3/captions/{captionId}?key={API_KEY}`).
    4.  下载字幕内容（通常是 XML 或 WebVTT 格式）。
    5.  解析字幕内容，提取纯文本和带时间戳的句子。

##### 5.2. Gemini API (获取释义和翻译 - 批量处理)

*   **用途**: 为提取的生词提供中文释义，并翻译例句。
*   **认证**: 需要配置 Gemini API Key。
*   **流程**:
    1.  **构建批量请求**: 将待处理的单词列表和相关的字幕文本（或包含单词的例句列表）打包成一个请求发送给 Gemini API。
    2.  **Prompt 设计**: 设计一个清晰的 Prompt，指示 Gemini API 返回一个结构化的 JSON 响应，其中包含每个单词的中文释义、原始英文例句及其对应的中文翻译。
        *   **示例 Prompt 结构**: "Given the following list of words: [word1, word2, ...], and the video subtitle text: '...', provide a concise Chinese definition for each word, and for each word, find one original English sentence from the subtitle where it appears, along with its Chinese translation. Return the results in JSON format."
    3.  **解析批量响应**: 解析 Gemini API 返回的结构化 JSON 响应，提取所需信息。

#### 6. 功能设计详述

##### 6.1. 生词本入口 (FR-601)

*   **位置**: `PlayerView` 的顶部导航栏右侧或播放控制区。
*   **图标**: 建议使用 SF Symbols 中的 `book.closed` 或 `pencil.and.book`。
*   **可见性**:
    *   默认可见。
    *   当视频字幕成功加载后，该按钮变为可交互状态（避免点击后无内容）。

##### 6.2. 生词本生成与持久化 (FR-602)

*   **触发**: 用户首次点击某个视频的“生词本”按钮。
*   **`VocabularyService` 职责**:
    1.  **检查现有数据**: 查询 SwiftData，判断 `videoID` 是否已存在关联的 `VideoVocabulary` 数据。
    2.  **获取字幕**: 调用 YouTube Data API 获取英文字幕。
    3.  **文本处理**:
        *   **分词**: 将字幕文本分割成单词。
        *   **小写化**: 所有单词转换为小写。
        *   **去除标点**: 移除单词中的标点符号。
        *   **过滤停用词**: 使用 **可配置的停用词列表** 过滤掉常见词。
        *   **去重**: 确保每个单词只处理一次。
    4.  **获取释义和翻译 (批量)**:
        *   将筛选出的单词列表和字幕文本传递给 Gemini API 进行批量处理。
        *   解析批量响应，获取每个单词的中文释义和例句翻译。
    5.  **保存到 SwiftData**:
        *   为每个生词创建或查找 `VocabularyWord` 实例。如果单词已存在于总生词本中，则使用现有实例；否则，创建新实例并插入。
        *   为每个视频中的单词实例创建 `VideoVocabulary` 实例，并将其与 `VocabularyWord` 和 `Video` 关联。
        *   确保所有操作都在 `ModelContext` 中进行，并适时调用 `modelContext.save()`。

##### 6.3. 生词本展示界面 (`VocabularyView`) (FR-603)

*   **UI 布局**: 列表或网格形式展示生词。
*   **生词条目**:
    *   **单词**: 醒目显示。
    *   **释义**: Gemini API 提供的中文释义。
    *   **例句**: 原始英文例句及其中文翻译。
    *   **难度标注**:
        *   使用 `Picker` 或 `SegmentedPicker` 提供 `简单`、`容易`、`一般`、`困难`、`太难` 选项。
        *   用户选择后，实时更新 `VocabularyWord` 实例的 `difficulty` 属性到 SwiftData。
    *   **发音**: 可选地集成 `AVSpeechSynthesizer` 提供单词发音功能。

##### 6.4. 总生词本 (`MasterVocabularyView`) (FR-604)

*   **入口**: `VideoListView` 的工具栏中新增一个“我的生词本”或“词汇库”按钮。**该按钮将始终可见，不限于家长模式。**
*   **UI 布局**: 列表形式展示所有 `VocabularyWord`。
*   **功能**:
    *   **筛选**: 按难度、按平台（YouTube/Bilibili）、按是否已掌握等。
    *   **排序**: 按字母顺序、按添加日期（新旧）、按难度。
    *   **搜索**: 允许搜索特定单词。
    *   **详情**: 点击单词可查看其在不同视频中的所有例句和翻译。

##### 6.5. API Key 管理 (FR-605)

*   **需求描述**: 提供一个界面，允许家长输入和管理 YouTube Data API Key 和 Gemini API Key。
*   **入口**: 在“家长模式”下，`VideoListView` 的工具栏中新增一个“API 设置”按钮（建议使用 `key.fill` 或 `gearshape.fill` 图标）。**此入口仍仅在家长模式下可见，以确保 API Key 的安全性。**
*   **`APISettingsView.swift`**: 
    *   **界面元素**: 包含两个 `TextField`，分别用于输入 YouTube API Key 和 Gemini API Key。
    *   **保存**: 提供一个“保存”按钮，将输入的 Key 安全地存储到 `UserSettings` 中。
    *   **验证**: 可选地，在保存时进行简单的格式验证。
*   **`UserSettings.swift`**: 
    *   新增属性，用于存储 `youtubeAPIKey` 和 `geminiAPIKey`。
    *   使用 `UserDefaults` 或 `Keychain` 进行安全存储。

##### 6.6. 停用词管理 (FR-606)

*   **需求描述**: 提供一个界面，允许家长或小朋友查看、添加、编辑和删除用于生词过滤的停用词。
*   **入口**: `VideoListView` 的工具栏中新增一个“停用词设置”按钮。**该按钮将始终可见，不限于家长模式。**
*   **`StopWordsSettingsView.swift`**: 
    *   **界面元素**: 
        *   一个可编辑的文本区域或列表，显示当前的停用词列表。
        *   添加新词的输入框和按钮。
        *   删除现有词的按钮。
    *   **保存**: 提供一个“保存”按钮，将修改后的停用词列表存储到 `UserSettings` 中。
*   **`UserSettings.swift`**: 
    *   新增属性，用于存储 `stopWords` 数组（`[String]`）。
    *   提供默认的停用词列表。
*   **`VocabularyService.swift`**: 
    *   修改生词过滤逻辑，从 `UserSettings` 获取当前的停用词列表。

#### 7. 非功能性需求

*   **性能**:
    *   生词提取和 API 调用应异步进行，避免阻塞 UI。
    *   大量生词的展示和筛选应保持流畅。
*   **可用性**:
    *   界面设计应直观，易于儿童操作。
    *   难度标注的交互应简单明了。
*   **安全性**:
    *   **API Keys 存储**: API Keys 应安全存储，不应直接硬编码在客户端代码中。建议使用 `UserDefaults` (对于非高度敏感数据) 或 `Keychain` (对于高度敏感数据)。
    *   遵守 YouTube Data API 和 Gemini API 的使用条款。

#### 8. 暂不包含的功能 (Out of Scope for V1.0)

*   单词复习提醒系统。
*   单词测验功能。
*   多用户（多孩子）生词本管理。

#### 9. 高层实现步骤

1.  **API Keys 配置**: 修改为从 `UserSettings` 获取 API Key。
2.  **定义 SwiftData 模型**: 实现 `VocabularyWord` 和 `VideoVocabulary` 模型，并更新 `Video` 模型。
3.  **实现 `UserSettings.swift`**: 添加 API Key 和**停用词列表**的存储和读取逻辑。
4.  **实现 `APISettingsView.swift`**: 创建 API Key 设置界面。
5.  **实现 `StopWordsSettingsView.swift`**: 创建停用词设置界面。
6.  **实现 `VocabularyService`**:
    *   字幕获取和解析逻辑。
    *   文本处理（分词、过滤、去重），**使用可配置的停用词列表**。
    *   **Gemini API 批量调用和结果解析**。
    *   SwiftData 插入和更新逻辑。
7.  **实现 `VocabularyView`**: 
    *   UI 布局和生词展示。
    *   难度标注交互和持久化。
8.  **实现 `MasterVocabularyView`**: 
    *   UI 布局和所有生词展示。
    *   筛选、排序和搜索功能。
9.  **集成到 `PlayerView` 和 `VideoListView`**: 添加生词本入口按钮、API 设置入口和**停用词设置入口**。
10. **测试**: 全面测试生词的提取、保存、展示、难度标注和 API Key 配置功能。