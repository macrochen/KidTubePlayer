# KidTubePlayer - iOS App Development Tasks

这是将我们的产品设计和UI原型转化为一个功能性iPad应用的具体开发步骤清单。

---

### 阶段一：项目设置与基础架构 (Phase 1: Project Setup & Architecture)

- [ ] **任务 1.1: 配置项目环境**
    - [ ] 在 Xcode 中，将项目目标设备设置为仅支持 iPad。
    - [ ] 将支持的设备方向限制为仅横屏 (Landscape Left & Landscape Right)。

- [ ] **任务 1.2: 数据模型定义**
    - [ ] 创建一个新的Swift文件 `Video.swift`。
    - [ ] 在此文件中定义一个 `Video` 结构体 (Struct)，使其遵循 `Identifiable` 和 `Codable` 协议。
    - [ ] 结构体应包含以下属性：`id` (String, YouTube视频ID), `title` (String), `thumbnailURL` (URL)。

- [ ] **任务 1.3: 内容提供者**
    - [ ] 创建一个新的Swift文件 `VideoProvider.swift`。
    - [ ] 在此文件中创建一个 `VideoProvider` 类或结构体。
    - [ ] 实现一个��态方法或属性，用于返回一个硬编码的 `[Video]` 数组，数据来源为【产品设计文档.md】中的虚拟数据表。

---

### 阶段二：视频列表页 (Phase 2: Video List View)

- [ ] **任务 2.1: 创建视频卡片视图**
    - [ ] 创建一个新的SwiftUI视图文件 `VideoCardView.swift`。
    - [ ] 设计该视图以完全匹配 `Homepage.html` 中的卡片样式（缩略图、标题、描述）。
    - [ ] 视图应接受一个 `Video` 对象作为输入。
    - [ ] 使用 `AsyncImage` 来异步加载和显示视频缩略图。

- [ ] **任务 2.2: 创建主列表视图**
    - [ ] 创建一个新的SwiftUI视图文件 `VideoListView.swift`。
    - [ ] 实现UI布局，使其与 `Homepage.html` 的iPad版本设计一致（大标题、欢迎语等）。
    - [ ] 使用 `LazyVGrid` 来创建一个4列的网格布局。
    - [ ] 从 `VideoProvider` 获取视频数据，并使用 `ForEach` 循环和 `VideoCardView` 来填充网格。
    - [ ] 添加 "Powered by YouTube" 文本到页脚。
    - [ ] 将整个视图包裹在 `NavigationStack` 中，为后续的页面跳转做准备。

---

### 阶段三：��频播放页 (Phase 3: Video Player View)

- [ ] **任务 3.1: 创建YouTube播放器视图**
    - [ ] 创建一个新的Swift文件 `YouTubePlayerView.swift`。
    - [ ] 使用 `UIViewRepresentable` 来封装一个 `WKWebView`。
    - [ ] 实现逻辑，根据传入的 `videoID` 构建YouTube IFrame Player API的URL。
    - [ ] 在URL参数中强制开启英文字幕 (`cc_load_policy=1`, `cc_lang_pref=en`) 并隐藏相关视频 (`rel=0`)。

- [ ] **任务 3.2: 创建播放器主视图**
    - [ ] 创建一个新的SwiftUI视图文件 `PlayerView.swift`。
    - [ ] 视图接收一个 `Video` 对象。
    - [ ] 将 `YouTubePlayerView` 作为背景，并使其全屏显示。
    - [ ] 在 `YouTubePlayerView` 之上叠加一个SwiftUI视图层，用于自定义控件，使其样式匹配 `PlayerPage.html` 的iPad版本设计。

- [ ] **任务 3.3: 实现自定义播放控件**
    - [ ] **返回按钮**: 实现一个返回按钮，点击后可从 `NavigationStack` 中弹出当前视图。
    - [ ] **播放/暂停/速度控制**:
        - 创建与UI设计稿匹配的按钮。
        - 实现通过 `WKWebView.evaluateJavaScript` 调用YouTube IFrame Player API的 `playVideo()`, `pauseVideo()`, 和 `setPlaybackRate()` 函数。
    - [ ] **进度条**: (此为高级功能，可初步简化)
        - 初步实现一个静态的UI进度条。
        - (可选) 尝试通过JavaScript轮询 `getCurrentTime()` 和 `getDuration()` 来实现动态更新。

---

### 阶段四：整合与收尾 (Phase 4: Integration & Finalization)

- [ ] **任务 4.1: 连接视图**
    - [ ] 在 `VideoListView.swift` 中，为每个 `VideoCardView` 添加 `NavigationLink`，使其在被点击时能导航到 `PlayerView`，并传递对应的 `Video` 对象。

- [ ] **任务 4.2: 设置App入口**
    - [ ] 修改 `KidTubePlayerApp.swift` 文件。
    - [ ] 将 `WindowGroup` 的内容设置为 `VideoListView`，使其成为App启动时加载的第一个页面。

- [ ] **任务 4.3: 清理与测试**
    - [ ] 删除 `ContentView.swift` 和其他模板代码。
    - [ ] 在模拟器上运行并测试完整流程：启动App -> 浏览列表 -> 点击视频 -> 观看视频 -> 控制播放 -> 返回列表。
