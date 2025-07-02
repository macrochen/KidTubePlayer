import SwiftUI

struct VideoPlayerWithPlaylistView: View {
    // 这个视图拥有 ViewModel
    @StateObject var viewModel: PlayerViewModel

    var body: some View {
        // 使用横向布局
        HStack(spacing: 0) {
            // 左侧：我们之前创建的 PlayerView
            PlayerView(viewModel: viewModel)
            
            // 右侧：我们刚刚创建的侧边栏
            PlaylistSidebarView(viewModel: viewModel)
        }
        // 确保视图忽略安全区域，占满整个屏幕
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}