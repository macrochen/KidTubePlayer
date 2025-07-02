
import SwiftUI

struct VideoListView: View {
    @StateObject private var videoImporter = VideoImporter()
    @State private var isImporting = false
    @State private var editMode: EditMode = .inactive
    @State private var selectedVideoIds: Set<String> = []
    @State private var isShowingDeleteConfirmation = false
    
    // 新增一个状态，用于控制导入结果提示框的显示
    @State private var isShowingImportResult = false

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
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if editMode.isEditing {
                        Button("Delete") {
                            isShowingDeleteConfirmation = true
                        }
                        .disabled(selectedVideoIds.isEmpty)
                    } else {
                        Button("Import") {
                            isImporting = true
                        }
                    }
                }
            }
            .sheet(isPresented: $isImporting) {
                DocumentPicker { url in
                    videoImporter.importVideos(from: url)
                }
            }
            .alert("删除视频", isPresented: $isShowingDeleteConfirmation) {
                Button("删除", role: .destructive) { deleteSelectedVideos() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("你确定要删除选中的视频吗？")
            }
            // 关键：监听 videoImporter.importResult 的变化
            // 【已修改】
            // 关键：监听 videoImporter.importResult 的变化
            // 为了兼容 iOS 17，将闭包参数改为接收两个值
            .onChange(of: videoImporter.importResult) { _, newValue in
                // 只要新结果不是 nil，就准备显示提示框
                if newValue != nil {
                    isShowingImportResult = true
                }
            }
            // 关键：定义导入结果的提示框
            .alert(
                "导入结果",
                isPresented: $isShowingImportResult,
                presenting: videoImporter.importResult // 将结果数据传递给 alert
            ) { result in
                Button("好") {
                    // 点击后重置结果，以便下次还能触发
                    videoImporter.importResult = nil
                }
            } message: { result in
                // 【已修改】
                // 直接调用新函数来获取消息字符串，然后用 Text 显示
                // 这样就避免了在视图层级中进行计算
                Text(importAlertMessage(for: result))
            }
            .environment(\.editMode, $editMode)
            .navigationDestination(for: Video.self) { video in
                PlayerView(video: video)
            }
        }
    }

    private func deleteSelectedVideos() {
        videoImporter.deleteVideos(with: selectedVideoIds)
        selectedVideoIds.removeAll()
        editMode = .inactive
    }
    
    // 【新增的辅助函数】
    // 将拼接字符串的逻辑从 body 中抽离出来
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
