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
    let sharedModelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([Video.self, PlaybackRecord.self])
            let modelConfiguration = ModelConfiguration(schema: schema, url: URL.applicationSupportDirectory.appending(path: "KidTubePlayer.sqlite"))
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            VideoListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
