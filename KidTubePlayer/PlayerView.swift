import SwiftUI

struct PlayerView: View {
    @Environment(\.presentationMode) var presentationMode
    let video: Video

    var body: some View {
        ZStack {
            // 第一层：播放器视图，填满整个背景
            YouTubePlayerView(videoID: video.id)
                .background(Color.black)

            // 第二层：UI覆盖层，包含返回按钮
            VStack {
                HStack {
                    // 返回按钮
                    Button(action: {
                        // 点击时调用 dismiss 返回上一页
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding([.top, .leading]) // 给按钮一些边距，让它离开屏幕边缘

                    Spacer() // 将按钮推到左侧
                }
                Spacer() // 将整个 HStack 推到顶部
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
        PlayerView(video: VideoProvider.allVideos.first!)
            .previewDevice("iPad Pro (11-inch) (4th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
