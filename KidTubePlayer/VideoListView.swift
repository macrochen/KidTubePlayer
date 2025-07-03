
import SwiftUI

struct VideoListView: View {
    @StateObject private var videoImporter = VideoImporter()
    @StateObject private var appSettings = AppSettings() // 管理家长模式状态
    
    @State private var isImporting = false
    @State private var editMode: EditMode = .inactive
    @State private var selectedVideoIds: Set<String> = []
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingImportResult = false
    
    // 控制密码输入页面的显示
    @State private var isShowingParentalGate = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    HeaderView()
                    
                    if videoImporter.videos.isEmpty {
                        EmptyStateView()
                    } else {
                        VideoGridView(
                            videoImporter: videoImporter,
                            selectedVideoIds: $selectedVideoIds,
                            editMode: $editMode
                        )
                    }
                }
                .padding(40)
            }
            .background(Color(white: 0.97))
            .ignoresSafeArea()
            .toolbar {
                // 根据是否解锁家长模式，显示不同的工具栏
                if appSettings.isParentalModeUnlocked {
                    parentalToolbar
                } else {
                    kidToolbar
                }
            }
            .sheet(isPresented: $isImporting) {
                DocumentPicker { url in
                    videoImporter.importVideos(from: url)
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
            .onChange(of: videoImporter.importResult) { _, newValue in
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
                    NavigationLink(destination: PlaybackHistoryView()) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("播放历史")
                    }
                    
                    Button("导入") { isImporting = true }
                    
                    if editMode.isEditing {
                        Button("完成") {
                            editMode = .inactive
                            selectedVideoIds.removeAll()
                        }
                    } else {
                        Button("编辑") { editMode = .active }
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
        videoImporter.deleteVideos(with: selectedVideoIds)
        selectedVideoIds.removeAll()
        editMode = .inactive
    }
    
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
    @ObservedObject var videoImporter: VideoImporter
    @Binding var selectedVideoIds: Set<String>
    @Binding var editMode: EditMode

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 40) {
            ForEach(videoImporter.videos) { video in
                if editMode.isEditing {
                    VideoCardView(video: video, isSelected: selectedVideoIds.contains(video.id))
                        .onTapGesture {
                            toggleSelection(for: video)
                        }
                } else {
                    NavigationLink(value: video) {
                        VideoCardView(video: video)
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
