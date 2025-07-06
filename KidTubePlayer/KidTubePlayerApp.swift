//
//  KidTubePlayerApp.swift
//  KidTubePlayer
//
//  Created by jolin on 2025/6/30.
//

import SwiftUI
import SwiftData

@main
struct KidTubePlayerApp: App {
    // 将 ModelContainer 的初始化放到一个闭包里
    // 这样做更清晰，并且可以让 SwiftData 自动管理数据库文件的存储位置
    let sharedModelContainer: ModelContainer = {
        // 1. 定义你的数据模型 Schema
        let schema = Schema([
            Video.self,
            PlaybackRecord.self
        ])
        
        // 2. 创建一个模型配置，但不指定具体的 URL
        // isStoredInMemoryOnly: false 表示数据会持久化存储在磁盘上
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            // 3. 使用这个配置来创建容器
            // 这是推荐的方式，可以避免很多文件路径和权限相关的问题
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 如果这里仍然报错，问题可能出在你的 Model 定义上
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            VideoListView()
        }
        // 将创建好的容器注入到视图环境中
        .modelContainer(sharedModelContainer)
    }
}
