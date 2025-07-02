import SwiftUI

struct PlayerView: View {
    @Environment(\.presentationMode) var presentationMode
    let video: Video

    var body: some View {
        ZStack {
            // 关键：根据平台选择不同的播放器
            switch video.platform {
            case .youtube:
                YouTubePlayerView(videoID: video.id)
                    .background(Color.black)
            case .bilibili:
                BilibiliPlayerView(videoID: video.id)
                    .background(Color.black)
            }

            // UI 覆盖层（返回按钮）保持不变
            VStack {
                HStack {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding([.top, .leading])

                    Spacer()
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        // 更新预览以使用新的 Video 构造函数
        PlayerView(video: VideoProvider.allVideos.first!)
            .previewDevice("iPad Pro (11-inch) (4th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
