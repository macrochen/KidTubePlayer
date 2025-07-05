### KidTubePlayer - 生词本功能开发任务计划

**文档版本**: V1.0
**创建日期**: 2025年7月4日
**创建人**: Gemini
**状态**: 草稿

---

本计划旨在指导 KidTubePlayer 应用中“生词本”功能的开发。请按照以下阶段和任务逐步进行。

---

### 阶段一：核心数据模型与用户设置 (Core Data Models & User Settings)

**目标**: 定义生词本相关的数据模型，并实现 API Key 和停用词的持久化存储。

-   [x] **任务 1.1: 定义 `VocabularyWord` SwiftData 模型**
    -   [ ] 创建新文件 `KidTubePlayer/VocabularyWord.swift`。
    -   [ ] 定义 `VocabularyWord` 类，包含 `word`, `definition`, `difficulty`, `addedDate` 属性。
    -   [ ] 设置 `word` 为唯一属性。
    -   [ ] 定义与 `VideoVocabulary` 的关系。

-   [x] **任务 1.2: 定义 `VideoVocabulary` SwiftData 模型**
    -   [ ] 创建新文件 `KidTubePlayer/VideoVocabulary.swift`。
    -   [ ] 定义 `VideoVocabulary` 类，包含 `videoID`, `originalSentence`, `translatedSentence` 属性。
    -   [ ] 定义与 `VocabularyWord` 和 `Video` 的关系。

-   [x] **任务 1.3: 更新 `Video` SwiftData 模型**
    -   [ ] 打开 `KidTubePlayer/Video.swift`。
    -   [ ] 添加与 `VideoVocabulary` 的关系属性 `videoVocabularies`。

-   [x] **任务 1.4: 更新 `KidTubePlayerApp.swift`**
    -   [ ] 打开 `KidTubePlayer/KidTubePlayerApp.swift`。
    -   [ ] 在 `ModelContainer` 中注册新的 `VocabularyWord` 和 `VideoVocabulary` 模型。

-   [x] **任务 1.5: 实现 `UserSettings.swift` 中的 API Key 和停用词存储**
    -   [ ] 打开 `KidTubePlayer/UserSettings.swift` (如果不存在则创建)。
    -   [ ] 添加 `youtubeAPIKey` 和 `geminiAPIKey` 属性，使用 `UserDefaults` 进行存储。
    -   [ ] 添加 `stopWords` 属性，使用 `UserDefaults` 进行存储，并提供默认的停用词列表。
    -   [ ] 实现相应的 getter/setter 方法。

---

### 阶段二：API 客户端与业务逻辑服务 (API Clients & Business Logic Service)

**目标**: 实现与 YouTube 和 Gemini API 的交互，以及生词提取和处理的核心逻辑。

-   [x] **任务 2.1: 实现 YouTube Data API 客户端 (获取字幕)**
    -   [ ] 创建新文件 `KidTubePlayer/YouTubeCaptionService.swift`。
    -   [ ] 实现获取指定 `videoID` 英文字幕的方法。
    -   [ ] 从 `UserSettings` 获取 YouTube API Key。
    -   [ ] 处理 API 请求、响应解析（XML 或 WebVTT）。

-   [x] **任务 2.2: 实现 Gemini API 客户端 (批量获取释义和翻译)**
    -   [ ] 创建新文件 `KidTubePlayer/GeminiService.swift`。
    -   [ ] 实现批量处理单词列表和字幕文本，返回结构化释义和例句翻译的方法。
    -   [ ] 从 `UserSettings` 获取 Gemini API Key。
    -   [ ] 设计合适的 Prompt 结构。
    -   [ ] 处理 API 请求、响应解析。

-   [x] **任务 2.3: 实现 `VocabularyService.swift`**
    -   [ ] 创建新文件 `KidTubePlayer/VocabularyService.swift`。
    -   [ ] 注入 `YouTubeCaptionService` 和 `GeminiService` 依赖。
    -   [ ] 实现 `generateVocabulary(for video: Video, modelContext: ModelContext)` 方法：
        -   [ ] 检查 SwiftData 中是否已存在该视频的生词数据。
        -   [ ] 调用 `YouTubeCaptionService` 获取字幕。
        -   [ ] 实现文本处理逻辑（分词、小写化、去除标点）。
        -   [ ] 从 `UserSettings` 获取停用词列表，并过滤单词。
        -   [ ] 调用 `GeminiService` 批量获取释义和翻译。
        -   [ ] 将处理后的数据保存到 SwiftData (`VocabularyWord` 和 `VideoVocabulary`)。

---

### 阶段三：UI - 设置界面 (UI - Settings Views)

**目标**: 提供 API Key 和停用词的配置界面。

-   [x] **任务 3.1: 实现 `APISettingsView.swift`**
    -   [ ] 创建新文件 `KidTubePlayer/APISettingsView.swift`。
    -   [ ] 设计 UI，包含 `TextField` 用于输入 YouTube 和 Gemini API Key。
    -   [ ] 实现“保存”按钮，将 Key 存储到 `UserSettings`。

-   [x] **任务 3.2: 实现 `StopWordsSettingsView.swift`**
    -   [ ] 创建新文件 `KidTubePlayer/StopWordsSettingsView.swift`。
    -   [ ] 设计 UI，显示当前停用词列表，并提供添加/编辑/删除功能。
    -   [ ] 实现“保存”按钮，将修改后的列表存储到 `UserSettings`。

-   [x] **任务 3.3: 集成设置入口到 `VideoListView.swift`**
    -   [ ] 打开 `KidTubePlayer/VideoListView.swift`。
    -   [ ] 在家长模式下的工具栏中添加 `NavigationLink` 到 `APISettingsView`。
    -   [ ] 在非家长模式和家长模式下的工具栏中添加 `NavigationLink` 到 `StopWordsSettingsView`。

---

### 阶段四：UI - 生词本展示界面 (UI - Vocabulary Display Views)

**目标**: 实现视频内生词本和总生词本的展示界面。

-   [x] **任务 4.1: 实现 `VocabularyView.swift` (视频内生词本)**
    -   [ ] 创建新文件 `KidTubePlayer/VocabularyView.swift`。
    -   [ ] 接收 `Video` 对象作为参数。
    -   [ ] 使用 `@Query` 获取该视频相关的 `VideoVocabulary` 数据。
    -   [ ] 设计 UI，展示单词、释义、例句、翻译。
    -   [ ] 实现难度标注的 UI 和逻辑，更新 `VocabularyWord` 的 `difficulty` 属性。
    -   [ ] (可选) 实现单词发音功能。

-   [x] **任务 4.2: 实现 `MasterVocabularyView.swift` (总生词本)**
    -   [ ] 创建新文件 `KidTubePlayer/MasterVocabularyView.swift`。
    -   [ ] 使用 `@Query` 获取所有 `VocabularyWord` 数据。
    -   [ ] 设计 UI，展示所有生词，并提供筛选、排序、搜索功能。
    -   [ ] 点击单词可查看其详情（例如，在哪些视频中出现过，所有例句）。

-   [x] **任务 4.3: 集成生词本入口到 `PlayerView.swift`**
    -   [ ] 打开 `KidTubePlayer/PlayerView.swift`。
    -   [ ] 在顶部导航栏或控制区添加“生词本”按钮。
    -   [ ] 实现按钮的逻辑，导航到 `VocabularyView`，并传递当前视频信息。
    -   [ ] 确保按钮在字幕加载成功后变为可交互状态。

-   [x] **任务 4.4: 集成总生词本入口到 `VideoListView.swift`**
    -   [ ] 打开 `KidTubePlayer/VideoListView.swift`。
    -   [ ] 在工具栏中添加 `NavigationLink` 到 `MasterVocabularyView`。

---

### 阶段五：集成与测试 (Integration & Testing)

**目标**: 连接所有组件，并进行全面的功能和性能测试。

-   [ ] **任务 5.1: 全面功能测试**
    -   [ ] 测试 API Key 设置和停用词设置的保存和加载。
    -   [ ] 测试生词本的生成：点击按钮 -> 字幕获取 -> Gemini API 调用 -> 数据保存。
    -   [ ] 测试生词本展示界面：单词、释义、例句、难度标注、发音。
    -   [ ] 测试总生词本：所有生词的展示、筛选、排序、搜索。
    -   [ ] 测试应用重启后，生词数据是否持久化。
    -   [ ] 确保所有功能在家长模式和非家长模式下的可见性符合预期。

-   [ ] **任务 5.2: 性能和内存分析**
    -   [ ] 使用 Xcode 的 Instruments 工具，检查生词提取和 API 调用时的性能和内存使用情况。
    -   [ ] 优化可能存在的性能瓶颈。

-   [ ] **任务 5.3: 错误处理和用户反馈**
    -   [ ] 确保 API 调用失败、网络问题等情况有友好的错误提示。
    -   [ ] 提供加载指示器，提升用户体验。
