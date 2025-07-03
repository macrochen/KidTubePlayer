import SwiftUI

struct PlayerView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject var viewModel: PlayerViewModel
    
    // 用于记录Bilibili播放开始时间
    @State private var bilibiliPlaybackStartTime: Date?

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
                    YouTubePlayerView(videoID: viewModel.video.id, videoTitle: viewModel.video.title)
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
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.black.opacity(0.3))
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear(perform: handleOnAppear)
        .onDisappear(perform: handleOnDisappear)
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
                PlaybackHistoryManager.shared.addRecord(record)
            }
            bilibiliPlaybackStartTime = nil
        }
    }
}


// 预览代码保持不变
struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleVideo = VideoProvider.allVideos.first!
        let viewModel = PlayerViewModel(singleVideo: sampleVideo)
        
        PlayerView(viewModel: viewModel)
            .previewDevice("iPad Pro (11-inch) (4th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
            .ignoresSafeArea()
    }
}
