# KidTubePlayer

KidTubePlayer is a specialized video player ecosystem designed for a controlled, focused viewing experience, particularly for children. It consists of an iOS application for playback and a companion browser extension for curating content.

The system is built to provide a safe, distraction-free environment by removing ads, comments, and recommended videos, allowing viewers to focus solely on a pre-selected playlist.

## How It Works

The workflow is designed to separate content curation from content consumption:

1.  **Curate Videos**: A parent or administrator uses the **Companion Browser Extension** on a desktop browser (like Chrome) to navigate YouTube or Bilibili. They can select desired videos directly from the website.
2.  **Export Playlist**: Once the playlist is compiled in the extension's UI, it can be exported as a `videos.json` file.
3.  **Import to App**: This `videos.json` file is transferred to the iPad (via AirDrop, Files, or email) and imported into the **KidTubePlayer iOS App**.
4.  **Watch**: The app then displays the curated videos in a simple, child-friendly grid, ready for distraction-free viewing.

## Core Features

### iOS Application

- **Distraction-Free Playback**: The custom player views for both YouTube and Bilibili hide all non-essential UI elements like comments, recommendations, and sharing buttons.
- **Multi-Platform Support**: Natively plays videos from both **YouTube** and **Bilibili**.
- **Local Playlist Management**: Import video lists from a JSON file. Videos are stored locally, and users can delete videos they no longer need.
- **Playback Persistence**: Remembers the playback progress and speed settings for each individual YouTube video.
- **Bilibili Multi-Part Handling**: Automatically detects and allows navigation through multi-part (分P) Bilibili videos.
- **iPad Optimized**: The user interface is designed for a landscape, iPad-first experience.

### Companion Browser Extension

- **Seamless Integration**: Adds a simple "+ Add" button directly onto video thumbnails on the YouTube and Bilibili websites.
- **Multi-Platform Curation**: Works with both YouTube and Bilibili, allowing for playlists that can contain videos from both sources.
- **Easy Export**: Compiles a selected list of videos and exports it into a `videos.json` file, ready to be used by the iOS app.
- **Simple UI**: A clean, floating panel shows the currently selected videos and allows for easy removal and exporting.

## Technical Stack

- **iOS Application**:
    - SwiftUI for the user interface and application structure.
    - `WebKit` (`WKWebView`) for embedding and controlling the web-based video players (YouTube IFrame Player and Bilibili Player).
- **Browser Extension**:
    - Standard Web technologies: JavaScript, HTML, CSS.
    - `Chrome Extension Manifest V3` API.

---

# KidTubePlayer (中文说明)

KidTubePlayer 是一个专为儿童设计的视频播放生态系统，旨在提供一个可控、专注的观看体验。它由一个用于播放的 iOS 应用程序和一个用于管理内容的配套浏览器扩展程序组成。

该系统旨在通过移除广告、评论和推荐视频，为孩子提供一个安全、纯净、无干扰的观看环境，让他们能专注于预设的播放列表。

## 工作流程

本系统的工作流程将内容管理与内容消费分离开来：

1.  **筛选视频**: 家长或管理员在电脑浏览器（如 Chrome）上使用**配套的浏览器扩展**，浏览 YouTube 或 Bilibili 网站，并直接从网站上选择想要的视频。
2.  **导出播放列表**: 在扩展程序的界面中完成视频选择后，可以将其导出为 `videos.json` 文件。
3.  **导入App**: 将 `videos.json` 文件传输到 iPad（通过隔空投送、文件或邮件），然后导入到 **KidTubePlayer iOS 应用**中。
4.  **观看**: 应用程序会以简洁、儿童友好的网格形式展示所有已筛选的视频，让孩子可以随时开始无干扰的观看。

## 核心功能

### iOS 应用

-   **无干扰播放**: 为 YouTube 和 Bilibili 定制的播放器视图会隐藏所有非必要的界面元素，如评论、推荐和分享按钮。
-   **跨平台支持**: 可原生播放来自 **YouTube** 和 **Bilibili** 的视频。
-   **本地列表管理**: 支持从 JSON 文件导入视频列表。视频数据存储在本地，用户可以随时删除不再需要的视频。
-   **播放进度记忆**: 能记住每个 YouTube 视频的播放进度和速度设置。
-   **Bilibili 多P支持**: 能自动检测并支持 Bilibili 视频的多P（分P）切换。
-   **iPad 优化**: 用户界面专为 iPad 横屏使用场景设计。

### 浏览器扩展

-   **无缝集成**: 在 YouTube 和 Bilibili 网站的视频缩略图上直接添加一个简洁的“+ 添加”按钮。
-   **跨平台筛选**: 同时支持 YouTube 和 Bilibili，可以创建包含两个平台视频的混合播放列表。
-   **轻松导出**: 将选定的视频列表编译并导出为 `videos.json` 文件，可直接用于 iOS 应用。
-   **简洁界面**: 一个悬浮在页面右下角的面板会清晰地展示当前已选的视频，并支持随时移除和导出。

## 技术栈

-   **iOS 应用**:
    -   **SwiftUI**: 用于构建用户界面和应用结构。
    -   **WebKit** (`WKWebView`): 用于嵌入和控制基于 Web 的视频播放器（YouTube IFrame Player 和 Bilibili Player）。
-   **浏览器扩展**:
    -   标准 Web 技术: JavaScript, HTML, CSS。
    -   `Chrome Extension Manifest V3` API。
