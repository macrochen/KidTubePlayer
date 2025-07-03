### KidTubePlayer 持久化层重构设计文档：从 JSON 到 SwiftData

**文档版本**: V1.0
**创建日期**: 2025年7月3日
**创建人**: Gemini
**状态**: 草稿

---

#### 1. 引言

当前 KidTubePlayer 应用的视频列表和播放历史记录均采用 JSON 文件进行持久化存储。随着应用功能的扩展和数据量的增长，基于文件的存储方式在数据管理、查询效率和可维护性方面逐渐显现出局限性。

本设计文档旨在提出一种将现有 JSON 持久化层迁移至 Apple 官方推荐的现代化数据持久化框架 **SwiftData** 的方案。SwiftData 基于 Core Data 构建，提供了更简洁的 API 和更好的 SwiftUI 集成，能够有效提升数据管理的效率和应用的性能。

#### 2. 目标

*   **提升数据管理效率**: 利用 SwiftData 的模型化管理，简化数据的增删改查操作。
*   **优化查询性能**: 借助 SwiftData 的底层优化，提高视频列表加载和播放历史查询的速度。
*   **增强可维护性**: 采用声明式 API，减少样板代码，使数据层逻辑更清晰、易于维护。
*   **更好的 SwiftUI 集成**: 利用 `@Query` 等属性包装器，实现数据与 UI 的无缝绑定和自动更新。
*   **支持未来扩展**: 为后续更复杂的数据关系和功能（如用户账户、播放列表分组）奠定基础。

#### 3. 受影响模块与文件

本次重构将主要影响以下文件和模块：

*   `Video.swift`: 视频数据模型，需转换为 SwiftData `@Model`。
*   `PlaybackRecord.swift`: 播放历史记录数据模型，需转换为 SwiftData `@Model`。
*   `VideoProvider.swift`: 当前负责硬编码视频数据和 JSON 解析，其职责将转移至 SwiftData 查询。
*   `VideoImporter.swift` (待实现): 负责 `videos.json` 导入的逻辑，需修改为将 JSON 数据导入 SwiftData。
*   `PlaybackHistoryManager.swift`: 当前负责 `playback_history.json` 的读写，其职责将完全由 SwiftData 取代。
*   `KidTubePlayerApp.swift`: 应用入口，需配置 `ModelContainer`。
*   `VideoListView.swift`: 视频列表展示，需修改为从 SwiftData 获取数据。
*   `PlayerView.swift` / `YouTubePlayerView.swift` / `BilibiliPlayerView.swift`: 播放记录的创建逻辑，需修改为通过 `ModelContext` 存储 `PlaybackRecord`。
*   `PlaybackHistoryView.swift`: 播放历史展示，需修改为从 SwiftData 获取数据。

#### 4. 解决方案：SwiftData 集成

##### 4.1. 数据模型定义

将现有的 `Video` 和 `PlaybackRecord` 结构体转换为 SwiftData 的 `@Model` 类。

**`Video.swift` 示例变更**:

```swift
// 原始 (简化)
// struct Video: Identifiable, Codable {
//     let id: String
//     let title: String
//     let thumbnailURL: URL
// }

// 迁移后
import Foundation
import SwiftData

@Model
final class Video {
    @Attribute(.unique) var id: String // YouTube Video ID
    var title: String
    var thumbnailURL: URL

    init(id: String, title: String, thumbnailURL: URL) {
        self.id = id
        self.title = title
        self.thumbnailURL = thumbnailURL
    }
}
```

**`PlaybackRecord.swift` 示例变更**:

```swift
// 原始 (简化)
// struct PlaybackRecord: Identifiable, Codable {
//     let id: UUID
//     let videoID: String
//     let videoTitle: String
//     let platform: String
//     let startTime: Date
//     let endTime: Date
//     let duration: TimeInterval
// }

// 迁移后
import Foundation
import SwiftData

@Model
final class PlaybackRecord {
    var videoID: String
    var videoTitle: String
    var platform: String // e.g., "YouTube", "Bilibili"
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval

    init(videoID: String, videoTitle: String, platform: String, startTime: Date, endTime: Date, duration: TimeInterval) {
        self.videoID = videoID
        self.videoTitle = videoTitle
        self.platform = platform
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
    }
}
```

##### 4.2. ModelContainer 配置

在 `KidTubePlayerApp.swift` 中配置 `ModelContainer`，使其在应用启动时可用。这将是 SwiftData 数据库的入口点。

```swift
import SwiftUI
import SwiftData

@main
struct KidTubePlayerApp: App {
    var body: some Scene {
        WindowGroup {
            VideoListView()
        }
        .modelContainer(for: [Video.self, PlaybackRecord.self]) // 注册所有需要管理的模型
    }
}
```

##### 4.3. 数据操作 (CRUD)

*   **创建/插入**:
    *   通过 `@Environment(\.modelContext)` 获取 `ModelContext`。
    *   创建 `@Model` 实例，然后调用 `modelContext.insert(instance)`。

    ```swift
    @Environment(\.modelContext) private var modelContext
    // ...
    let newVideo = Video(id: "...", title: "...", thumbnailURL: URL(string: "...")!)
    modelContext.insert(newVideo)
    try? modelContext.save() // 或依赖自动保存
    ```

*   **读取/查询**:
    *   在 SwiftUI 视图中使用 `@Query` 属性包装器进行声明式查询。
    *   对于更复杂的查询或在非视图上下文，使用 `ModelContext.fetch(FetchDescriptor<T>)`。

    ```swift
    // 在 VideoListView 中
    @Query(sort: \Video.title) var videos: [Video]
    // ...
    ForEach(videos) { video in
        VideoCardView(video: video)
    }
    ```

*   **更新**:
    *   直接修改已从 SwiftData 中获取的 `@Model` 实例的属性。SwiftData 会自动检测并保存更改。

    ```swift
    // 假设 video 是从 SwiftData 中获取的实例
    video.title = "New Title"
    // 无需显式保存，SwiftData 会自动处理
    ```

*   **删除**:
    *   通过 `modelContext.delete(instance)` 删除 `@Model` 实例。

    ```swift
    modelContext.delete(videoToDelete)
    ```

##### 4.4. 迁移策略 (现有 JSON 数据)

为了平滑过渡，需要考虑如何处理用户设备上已存在的 `videos.json` 和 `playback_history.json` 文件。

*   **一次性导入**: 在应用首次启动时（或检测到 SwiftData 数据库为空时），检查是否存在旧的 JSON 文件。如果存在，则读取其内容，将数据解析并导入到 SwiftData 数据库中。导入完成后，可以选择删除旧的 JSON 文件。
*   **版本控制**: SwiftData 支持模型架构迁移。如果未来数据模型发生变化，可以使用 `SchemaMigrationPlan` 进行数据迁移。

#### 5. 优势

*   **类型安全**: SwiftData 模型是强类型的，减少运行时错误。
*   **性能提升**: 底层 Core Data 针对数据库操作进行了优化，尤其在处理大量数据时表现更佳。
*   **自动更新 UI**: `@Query` 与 SwiftUI 深度集成，数据变化时 UI 自动刷新。
*   **简化代码**: 减少手动 JSON 编解码和文件 I/O 的复杂性。
*   **事务支持**: 数据库操作可以作为事务处理，确保数据一致性。

#### 6. 潜在挑战与考虑

*   **学习曲线**: 对于不熟悉 Core Data 或 SwiftData 的开发者，可能需要一定的学习时间。
*   **现有数据迁移**: 需要编写一次性脚本来处理旧 JSON 数据的导入。
*   **调试**: SwiftData 的调试可能比直接文件操作更复杂，需要熟悉 Xcode 的 Core Data 调试工具。
*   **并发**: 在多线程环境下操作 SwiftData 需要注意 `ModelContext` 的线程安全。

#### 7. 高层实现步骤

1.  **定义 SwiftData 模型**: 将 `Video.swift` 和 `PlaybackRecord.swift` 转换为 `@Model` 类。
2.  **配置 ModelContainer**: 在 `KidTubePlayerApp.swift` 中添加 `.modelContainer()` 修饰符。
3.  **重构数据提供者**:
    *   删除 `VideoProvider.swift` 中硬编码和 JSON 相关的逻辑。
    *   修改 `VideoListView` 和 `PlaybackHistoryView`，使用 `@Query` 从 SwiftData 获取数据。
4.  **更新数据操作**:
    *   修改 `VideoImporter.swift` (待实现) 中的导入逻辑，将 JSON 数据插入 SwiftData。
    *   删除 `PlaybackHistoryManager.swift`，将其功能直接集成到播放器视图中，通过 `ModelContext` 插入 `PlaybackRecord`。
5.  **实现一次性数据迁移**: 编写逻辑在应用首次启动时将旧 JSON 数据导入 SwiftData。
6.  **测试**: 全面测试所有数据操作，确保数据完整性和应用稳定性。
