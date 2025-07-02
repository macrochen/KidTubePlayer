import SwiftUI

struct PlayerView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject var viewModel: PlayerViewModel

    var body: some View {
        ZStack {
            // 背景色
            Color.black.ignoresSafeArea()
            
            // 播放器视图
            VStack {
                if viewModel.video.platform == .bilibili {
                    BilibiliPlayerView(
                        videoID: viewModel.video.id,
                        page: viewModel.currentPage
                    )
                    // 【核心修改】为播放器视图添加 .id() 修饰符
                    // 当 currentPage 变化时，这个 id 就会变化
                    // SwiftUI 会销毁旧的 BilibiliPlayerView，并创建一个全新的
                    .id(viewModel.currentPage)
                } else {
                    // YouTube 播放器
                    YouTubePlayerView(videoID: viewModel.video.id)
                }
            }
            
            // UI 覆盖层（返回按钮、标题）
            VStack {
                // 顶部栏：返回按钮和标题
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
                
                // 【已移除】
                // 此处原本用于显示“上一P/下一P”按钮的 HStack 已被完全删除。
                
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
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
