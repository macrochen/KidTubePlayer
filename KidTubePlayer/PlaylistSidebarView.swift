import SwiftUI

struct PlaylistSidebarView: View {
    // 使用 @ObservedObject，因为它只是观察和使用 ViewModel，而不是拥有它
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        // 使用 GeometryReader 来让列表可以滚动到当前播放项
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // 列表标题
                        Text("播放列表")
                            .font(.headline)
                            .padding()

                        // 循环创建所有分P的条目
                        ForEach(viewModel.parts) { part in
                            Button(action: {
                                // 点击按钮时，命令 ViewModel 跳转到这一P
                                viewModel.goToPart(page: part.page)
                            }) {
                                HStack {
                                    // 如果是当前播放的P，显示一个播放图标
                                    if viewModel.currentPage == part.page {
                                        Image(systemName: "play.fill")
                                            .foregroundColor(.accentColor)
                                            .font(.caption)
                                    }
                                    
                                    // 显示分P标题
                                    Text(part.part)
                                        .font(.system(size: 14))
                                        .lineLimit(2)
                                        .foregroundColor(viewModel.currentPage == part.page ? .accentColor : .primary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                // 如果是当前播放的P，背景高亮显示
                                .background(viewModel.currentPage == part.page ? Color.accentColor.opacity(0.2) : Color.clear)
                                .cornerRadius(5)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .id(part.page) // 给每个条目一个ID，方便滚动定位
                        }
                    }
                }
                .onChange(of: viewModel.currentPage) { newPage in
                    // 当 ViewModel 中的 currentPage 变化时，自动滚动到新的当前项
                    withAnimation {
                        proxy.scrollTo(newPage, anchor: .center)
                    }
                }
            }
        }
        .frame(width: 300) // 给侧边栏一个固定的宽度
        .background(Color(.secondarySystemBackground))
    }
}