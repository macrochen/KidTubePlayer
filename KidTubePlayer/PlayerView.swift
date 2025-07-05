import SwiftUI
import SwiftData

struct PlayerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    
    @StateObject var viewModel: PlayerViewModel
    @StateObject private var vocabularyService = VocabularyService() // Add VocabularyService
    
    // 用于记录Bilibili播放开始时间
    @State private var bilibiliPlaybackStartTime: Date?
    
    @State private var showVocabularySheet = false
    @State private var showGenerationErrorAlert = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                if viewModel.video.platform == .bilibili {
                    BilibiliPlayerView(
                        videoID: viewModel.video.id,
                        page: viewModel.currentPage
                    )
                    .id(viewModel.currentPage)
                } else {
                    YouTubePlayerView(videoID: viewModel.video.id, videoTitle: viewModel.video.title) { record in
                        modelContext.insert(record)
                    }
                }
            }
            
            VStack {
                HStack {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.title2)
                    }
                    
                    Text(viewModel.currentPartTitle)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await vocabularyService.generateVocabulary(for: viewModel.video, modelContext: modelContext)
                        }
                    }) {
                        Image(systemName: "book.closed")
                            .font(.title2)
                    }
                    .disabled(vocabularyService.status == .fetchingCaptions ||
                              vocabularyService.status == .processingText ||
                              vocabularyService.status == .fetchingDefinitionsAndExamples ||
                              vocabularyService.status == .savingToDatabase)
                    .onChange(of: vocabularyService.status) { newStatus in
                        if newStatus == .completed {
                            showVocabularySheet = true
                        } else if case .failed(let error) = newStatus {
                            showGenerationErrorAlert = true
                        }
                    }
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.black.opacity(0.3))
                
                Spacer()
                
                // Display status and progress
                if vocabularyService.status != .idle && vocabularyService.status != .completed {
                    VStack {
                        ProgressView()
                        Text(statusMessage(for: vocabularyService.status))
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear(perform: handleOnAppear)
        .onDisappear(perform: handleOnDisappear)
        .sheet(isPresented: $showVocabularySheet) {
            VocabularyView(video: viewModel.video)
                .environment(\.modelContext, modelContext) // Pass modelContext to the sheet
        }
        .alert("生词本生成失败", isPresented: $showGenerationErrorAlert, presenting: vocabularyService.errorMessage) { _ in
            Button("OK") {
                vocabularyService.errorMessage = nil
            }
        } message: { errorMessage in
            Text(errorMessage ?? "未知错误")
        }
    }
    
    private func handleOnAppear() {
        if viewModel.video.platform == .bilibili {
            bilibiliPlaybackStartTime = Date()
        }
    }
    
    private func handleOnDisappear() {
        if viewModel.video.platform == .bilibili {
            guard let startTime = bilibiliPlaybackStartTime else { return }
            let endTime = Date()
            
            if endTime.timeIntervalSince(startTime) > 5.0 {
                let record = PlaybackRecord(
                    videoID: viewModel.video.id,
                    videoTitle: viewModel.currentPartTitle, // 使用当前分P的标题
                    platform: .bilibili,
                    startTime: startTime,
                    endTime: endTime
                )
                modelContext.insert(record)
            }
            bilibiliPlaybackStartTime = nil
        }
    }
    
    private func statusMessage(for status: VocabularyGenerationStatus) -> String {
        switch status {
        case .idle: return ""
        case .checkingExistingData: return "检查现有生词数据..."
        case .fetchingCaptions: return "下载字幕中..."
        case .processingText: return "处理字幕文本..."
        case .fetchingDefinitionsAndExamples: return "生成生词释义和例句..."
        case .savingToDatabase: return "保存生词到数据库..."
        case .completed: return "生词本生成完成！"
        case .failed(let error): return "生成失败: \(error)"
        }
    }
}


// 预览代码保持不变
struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        // 预览时使用一个示例 Video 对象
        let sampleVideo = Video(id: "sampleID", platform: .youtube, title: "Sample Video Title", author: "Sample Author", viewCount: 1000, uploadDate: Date(), authorAvatarURL: nil, thumbnailURL: nil)
        let viewModel = PlayerViewModel(singleVideo: sampleVideo)
        
        PlayerView(viewModel: viewModel)
            .previewDevice("iPad Pro (11-inch) (4th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
            .ignoresSafeArea()
    }
}
