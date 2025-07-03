### KidTubePlayer - SwiftData 持久化重构开发任务计划

**文档版本**: V1.0
**创建日期**: 2025年7月3日
**创建人**: Gemini
**状态**: 草稿

---

本计划旨在指导 KidTubePlayer 应用的持久化层从 JSON 文件迁移到 SwiftData。请按照以下阶段和任务逐步进行。

---

### 阶段一：数据模型转换 (Model Conversion)

**目标**: 将现有 `Codable` 结构体转换为 SwiftData `@Model` 类。

-   [ ] **任务 1.1: 转换 `Video.swift` 为 SwiftData 模型**
    -   [ ] 打开 `KidTubePlayer/Video.swift`。
    -   [ ] 导入 `SwiftData` 框架。
    -   [ ] 将 `struct Video` 改为 `final class Video`。
    -   [ ] 添加 `@Model` 宏到 `Video` 类定义前。
    -   [ ] 将 `id` 属性添加 `@Attribute(.unique)` 宏，确保其唯一性。
    -   [ ] 确保所有属性（`id`, `title`, `thumbnailURL`）都是 `var`。
    -   [ ] 移除 `Identifiable` 和 `Codable` 协议遵循（SwiftData 模型自动遵循）。
    -   [ ] 保持现有的 `init` 方法不变。

-   [ ] **任务 1.2: 转换 `PlaybackRecord.swift` 为 SwiftData 模型**
    -   [ ] 打开 `KidTubePlayer/PlaybackRecord.swift`。
    -   [ ] 导入 `SwiftData` 框架。
    -   [ ] 将 `struct PlaybackRecord` 改为 `final class PlaybackRecord`。
    -   [ ] 添加 `@Model` 宏到 `PlaybackRecord` 类定义前。
    -   [ ] 移除 `Identifiable` 和 `Codable` 协议遵循。
    -   [ ] 保持现有的 `init` 方法不变。

---

### 阶段二：SwiftData 容器配置 (SwiftData Container Setup)

**目标**: 在应用启动时初始化 SwiftData 数据库。

-   [ ] **任务 2.1: 配置 `ModelContainer`**
    -   [ ] 打开 `KidTubePlayer/KidTubePlayerApp.swift`。
    -   [ ] 导入 `SwiftData` 框架。
    -   [ ] 在 `WindowGroup` 的 `body` 属性后添加 `.modelContainer(for: [Video.self, PlaybackRecord.self])` 修饰符。

---

### 阶段三：视频数据处理重构 (Video Data Handling Refactoring)

**目标**: 将视频列表的数据源从 `VideoProvider` 切换到 SwiftData。

-   [x] **任务 3.1: 移除 `VideoProvider.swift`**
    -   [ ] 删除文件 `KidTubePlayer/VideoProvider.swift`。

-   [x] **任务 3.2: 更新 `VideoListView.swift`**
    -   [ ] 打开 `KidTubePlayer/VideoListView.swift`。
    -   [ ] 导入 `SwiftData` 框架。
    -   [ ] 移除任何对 `VideoProvider` 的引用。
    -   [ ] 使用 `@Query` 属性包装器来获取视频数据：
        ```swift
        @Query(sort: \Video.title) var videos: [Video]
        ```
    -   [ ] 检查 `ForEach` 循环，确保它正确迭代 `videos` 数组。
    -   [ ] 检查 `VideoCardView` 的初始化，确保 `Video` 对象作为类实例传递。

-   [x] **任务 3.3: 更新 `VideoImporter.swift` (如果已存在)**
    -   [ ] 打开 `KidTubePlayer/VideoImporter.swift` (如果不存在，则在实现 V1.1 导入功能时再处理)。
    -   [ ] 导入 `SwiftData` 框架。
    -   [ ] 修改导入逻辑，使其将解析后的 `Video` 数据插入到 `ModelContext` 中，而不是返回 `[Video]` 数组。
    -   [ ] 需要通过 `@Environment(\.modelContext)` 或其他方式获取 `ModelContext`。

---

### 阶段四：播放历史处理重构 (Playback History Handling Refactoring)

**目标**: 将播放历史记录的数据源从 `PlaybackHistoryManager` 切换到 SwiftData。

-   [x] **任务 4.1: 移除 `PlaybackHistoryManager.swift`**
    -   [ ] 删除文件 `KidTubePlayer/PlaybackHistoryManager.swift`。

-   [ ] **任务 4.2: 更新播放器视图以记录历史**
    -   [ ] 打开 `KidTubePlayer/PlayerView.swift`。
    -   [ ] 导入 `SwiftData` 框架。
    -   [ ] 获取 `ModelContext`：
        ```swift
        @Environment(\.modelContext) private var modelContext
        ```
    -   [ ] 修改 `PlayerView` 中记录播放开始和结束时间的逻辑。
    -   [ ] 在适当的时机（例如，视频播放结束或用户退出播放页时），创建 `PlaybackRecord` 实例并使用 `modelContext.insert(newRecord)` 插入。
    -   [ ] 对 `KidTubePlayer/YouTubePlayerView.swift` 和 `KidTubePlayer/BilibiliPlayerView.swift` 进行类似修改，确保它们能够触发 `PlayerView` 中的记录逻辑，或者直接在这些视图中插入 `PlaybackRecord`。

-   [x] **任务 4.3: 更新 `PlaybackHistoryView.swift`**
    -   [ ] 打开 `KidTubePlayer/PlaybackHistoryView.swift`。
    -   [ ] 导入 `SwiftData` 框架。
    -   [ ] 移除任何对 `PlaybackHistoryManager` 的引用。
    -   [ ] 使用 `@Query` 属性包装器来获取播放历史数据：
        ```swift
        @Query(sort: \PlaybackRecord.startTime, order: .reverse) var records: [PlaybackRecord]
        ```
    -   [ ] 修改 UI 逻辑，使其根据 `records` 数组进行分组（按日期）和计算每日总时长。

---



---

### 阶段五：清理与测试 (Cleanup and Testing)

**目标**: 移除所有旧的 JSON 相关代码，并全面测试新数据层。

-   [x] **任务 6.1: 移除 JSON 文件 I/O 代码**
    -   [ ] 仔细检查所有文件，移除任何与 `FileManager`、`JSONEncoder`、`JSONDecoder` 相关的、用于读写 `videos.json` 和 `playback_history.json` 的代码。

-   [ ] **任务 6.2: 全面功能测试**
    -   [ ] 在模拟器上运行应用。
    -   [ ] **视频列表**: 验证视频列表是否正确显示。
    -   [ ] **视频播放**: 播放多个视频，确保播放器功能正常。
    -   [ ] **播放历史**: 验证播放历史是否正确记录并显示。
    -   [ ] **视频导入**: (如果 V1.1 导入功能已实现) 导入新的 `videos.json` 文件，验证视频是否成功添加到列表中。
    -   [ ] **视频删除**: (如果 V1.1 删除功能已实现) 尝试删除视频，验证是否成功。
    -   [ ] **数据迁移**: 
        -   [ ] 准备一个包含旧 `videos.json` 和 `playback_history.json` 的模拟器环境。
        -   [ ] 首次启动应用，验证旧数据是否成功迁移到 SwiftData。
        -   [ ] 再次启动应用，验证迁移逻辑是否只运行一次。

-   [ ] **任务 6.3: 性能和内存分析**
    -   [ ] 使用 Xcode 的 Instruments 工具，检查应用在数据操作时的性能和内存使用情况。
