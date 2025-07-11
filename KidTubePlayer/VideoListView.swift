
import SwiftUI
import SwiftData

struct VideoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Video.title) var videos: [Video]
    @Query var playbackRecords: [PlaybackRecord] // 新增：播放记录
    
    @StateObject private var appSettings = AppSettings() // 管理家长模式状态
    @StateObject private var videoImporter = VideoImporter() // Re-add VideoImporter
    
    @State private var isImporting = false // Re-add isImporting state
    @State private var isShowingImportResult = false // Re-add isShowingImportResult state
    @State private var isShowingPlaybackHistory = false // New state for PlaybackHistory navigation
    
    @State private var editMode: EditMode = .inactive
    @State private var selectedVideoIds: Set<String> = []
    @State private var isShowingDeleteConfirmation = false
    
    // 控制密码输入页面的显示
    @State private var isShowingParentalGate = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    HeaderView()
                    
                    if videos.isEmpty {
                        EmptyStateView()
                    } else {
                        VideoGridView(
                            videos: videos,
                            selectedVideoIds: $selectedVideoIds,
                            editMode: $editMode,
                            watchedPercentageProvider: { video in
                                watchedPercentage(for: video)
                            }
                        )
                    }
                }
                .padding(40)
            }
            .background(Color(white: 0.97))
            .ignoresSafeArea()
            .toolbar {
                if appSettings.isParentalModeUnlocked {
                    parentalToolbar
                } else {
                    kidToolbar
                }
            }
            .sheet(isPresented: $isImporting) { // Re-add sheet for DocumentPicker
                DocumentPicker { url in
                    videoImporter.importVideos(from: url, modelContext: modelContext)
                }
            }
            // 新增：显示密码输入页面的 sheet
            .sheet(isPresented: $isShowingParentalGate) {
                ParentalGateView(mode: UserSettings.isPasswordSet ? .unlock : .setup)
                    .environmentObject(appSettings)
            }
            .alert("删除视频", isPresented: $isShowingDeleteConfirmation) {
                Button("删除", role: .destructive) { deleteSelectedVideos() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("你确定要删除选中的视频吗？")
            }
            .onChange(of: videoImporter.importResult) { _, newValue in // Re-add onChange for importResult
                if newValue != nil {
                    isShowingImportResult = true
                }
            }
            .alert(
                "导入结果",
                isPresented: $isShowingImportResult,
                presenting: videoImporter.importResult
            ) { result in
                Button("好") {
                    videoImporter.importResult = nil
                }
            } message: { result in
                Text(importAlertMessage(for: result))
            }
            .environment(\.editMode, $editMode)
            .navigationDestination(for: Video.self) { video in
                if video.platform == .bilibili {
                    BilibiliLoadingDispatchView(video: video)
                } else {
                    let viewModel = PlayerViewModel(singleVideo: video)
                    PlayerView(viewModel: viewModel)
                }
            }
        }
    }
    
    // MARK: - Toolbars
    
    // 家长模式解锁后的工具栏
    private var parentalToolbar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    appSettings.isParentalModeUnlocked = false
                    editMode = .inactive
                }) {
                    Text("退出家长模式")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        if appSettings.isParentalModeUnlocked {
                            // Programmatically navigate to PlaybackHistoryView
                            // This requires a NavigationStack and a navigationDestination for PlaybackHistoryView
                            // For now, we'll just show the gate if not unlocked.
                            // A better approach might be to use a separate @State for navigation and trigger it here.
                            // For simplicity, I'll assume a direct navigation is intended if unlocked.
                            // If this causes issues, we might need to refactor navigation.
                            // For now, I'll just make it show the gate if not unlocked.
                            // If unlocked, it will proceed to the NavigationLink below.
                            // This is a placeholder for actual navigation.
                            // Since NavigationLink is declarative, we need a different approach.
                            // Let's use a @State to control navigation.
                            isShowingPlaybackHistory = true
                        } else {
                            isShowingParentalGate = true
                        }
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("播放历史")
                    }
                    .navigationDestination(isPresented: $isShowingPlaybackHistory) {
                        PlaybackHistoryView()
                    }
                    
                    Button("导入") {
                        if appSettings.isParentalModeUnlocked {
                            isImporting = true
                        } else {
                            isShowingParentalGate = true
                        }
                    }
                    
                    if editMode.isEditing {
                        Button("完成") {
                            editMode = .inactive
                            selectedVideoIds.removeAll()
                        }
                    } else {
                        Button("编辑") {
                            if appSettings.isParentalModeUnlocked {
                                editMode = .active
                            } else {
                                isShowingParentalGate = true
                            }
                        }
                    }
                    
                    if editMode.isEditing {
                        Button("删除") {
                            isShowingDeleteConfirmation = true
                        }
                        .disabled(selectedVideoIds.isEmpty)
                    }
                }
            }
        }
    }
    
    // 普通儿童模式下的工具栏
    private var kidToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                isShowingParentalGate = true
            }) {
                Image(systemName: "lock.shield")
                    .font(.title2)
            }
        }
    }
    
    private func deleteSelectedVideos() {
        for id in selectedVideoIds {
            if let videoToDelete = videos.first(where: { $0.id == id }) {
                modelContext.delete(videoToDelete)
            }
        }
        selectedVideoIds.removeAll()
        editMode = .inactive
    }
    
    // Re-add importAlertMessage function
    private func importAlertMessage(for result: ImportResult) -> String {
        if let errorMessage = result.errorMessage {
            return errorMessage
        } else {
            var message = "文件总共包含 \(result.totalInFile) 个视频。\n"
            message += "成功导入 \(result.successCount) 个新视频。"
            if result.duplicateCount > 0 {
                message += "\n\(result.duplicateCount) 个视频因为已存在而被跳过。"
            }
            return message
        }
    }
    
    private func watchedPercentage(for video: Video) -> Double {
        guard let videoDuration = video.duration, videoDuration > 0 else {
            return 0.0 // 如果视频时长未知或为0，则没有观看进度
        }
        
        // 从 UserDefaults 获取最新播放位置
        let progressKey = "progress-\(video.id)"
        let currentOffset = UserDefaults.standard.double(forKey: progressKey)
        
        // 计算观看百分比，并确保不超过1.0 (100%)
        return min(currentOffset / videoDuration, 1.0)
    }
    }
    
    // --- 其他子视图保持不变 ---
    
    struct EmptyStateView: View {
        var body: some View {
            VStack {
                Spacer()
                Image(systemName: "film.stack")
                    .font(.system(size: 80))
                    .foregroundColor(.gray.opacity(0.5))
                Text("No Videos")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                Text("Tap 'Import' to add your first video list.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 100)
        }
    }
    
    struct VideoGridView: View {
        var videos: [Video]
        @Binding var selectedVideoIds: Set<String>
        @Binding var editMode: EditMode
        var watchedPercentageProvider: (Video) -> Double // 新增：提供观看百分比的闭包
        
        private let columns = [
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20)
        ]
        
        var body: some View {
            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(videos) { video in
                    if editMode.isEditing {
                        VideoCardView(video: video, isSelected: selectedVideoIds.contains(video.id), watchedPercentage: watchedPercentageProvider(video))
                            .onTapGesture {
                                toggleSelection(for: video)
                            }
                    } else {
                        NavigationLink(value: video) {
                            VideoCardView(video: video, watchedPercentage: watchedPercentageProvider(video))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        
        private func toggleSelection(for video: Video) {
            if selectedVideoIds.contains(video.id) {
                selectedVideoIds.remove(video.id)
            } else {
                selectedVideoIds.insert(video.id)
            }
        }
    }
    
    struct HeaderView: View {
        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text("Welcome to KidTube!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Your favorite Minecraft videos for learning English.")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }
    
    struct VideoListView_Previews: PreviewProvider {
        static var previews: some View {
            VideoListView()
                .previewDevice("iPad Pro (11-inch) (4th generation)")
                .previewInterfaceOrientation(.landscapeLeft)
        }
    }

