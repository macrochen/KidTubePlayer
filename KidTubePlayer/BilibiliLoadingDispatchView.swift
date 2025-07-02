// BilibiliLoadingDispatchView.swift (使用 ZStack 稳定容器的最终版)

import SwiftUI

struct BilibiliLoadingDispatchView: View {
    let video: Video
    
    enum LoadState {
        case loading
        case success(PlayerViewModel)
        case failure(Error)
    }
    
    @State private var state: LoadState = .loading

    var body: some View {
        // 【核心修改】
        // 我们使用一个 ZStack 作为视图的根容器。
        // ZStack 是一个具体的、编译器明确知道其类型的视图。
        ZStack {
            // 将之前的 switch 逻辑完整地放入 ZStack 中
            switch state {
            case .loading:
                ProgressView("正在获取视频信息...")
                    .navigationTitle(video.title)
                    .navigationBarTitleDisplayMode(.inline)
            
            case .success(let viewModel):
                destinationView(for: viewModel)

            case .failure(let error):
                VStack(spacing: 20) {
                    Text("加载失败").font(.title)
                    Text(error.localizedDescription).font(.caption).foregroundColor(.secondary)
                    Button("重试") {
                        state = .loading
                        Task { await loadData() }
                    }
                }
            }
        }
        // 将 .onAppear 附加到这个稳定的 ZStack 容器上
        .onAppear {
            if case .loading = state {
                Task {
                    await loadData()
                }
            }
        }
    }
    
    // 辅助方法保持不变 (使用 @ViewBuilder 是好习惯)
    @ViewBuilder
    private func destinationView(for viewModel: PlayerViewModel) -> some View {
        if viewModel.parts.count > 1 {
            VideoPlayerWithPlaylistView(viewModel: viewModel)
        } else {
            PlayerView(viewModel: viewModel)
        }
    }
    
    // loadData 方法保持不变
    private func loadData() async {
        do {
            let parts = try await BilibiliAPIService.fetchVideoParts(bvid: video.id)
            let viewModel = PlayerViewModel(video: video, parts: parts, initialPage: 1)
            self.state = .success(viewModel)
        } catch {
            self.state = .failure(error)
        }
    }
}
