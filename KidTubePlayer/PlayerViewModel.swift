import Foundation

// 使用 @MainActor 确保所有对UI的更新都在主线程进行
@MainActor
class PlayerViewModel: ObservableObject {
    
    let video: Video          // 基础视频信息
    let parts: [VideoPart]    // 完整的分P列表
    
    @Published var currentPage: Int // 当前播放的P数，@Published 意味着它的改变会自动更新UI

    // 【新增】为单个视频（如YouTube）设计的便利构造器
    convenience init(singleVideo: Video) {
        // 因为是单集视频，我们为它创建一个只包含一集的“虚拟”分P列表
        let singlePart = VideoPart(cid: 0, page: 1, part: singleVideo.title)
        
        // 调用我们主要的全功能构造器
        self.init(video: singleVideo, parts: [singlePart], initialPage: 1)
    }

    init(video: Video, parts: [VideoPart], initialPage: Int) {
        self.video = video
        self.parts = parts
        self.currentPage = initialPage
    }
    
    // 计算属性：获取当前分P的标题
    var currentPartTitle: String {
        return parts.first { $0.page == currentPage }?.part ?? video.title
    }
    
    // 计算属性：判断是否可以切换到上一P
    var canGoToPrevious: Bool {
        // 如果当前P是列表中的第一P，则不能再往前了
        guard let currentIndex = parts.firstIndex(where: { $0.page == currentPage }) else { return false }
        return currentIndex > 0
    }
    
    // 计算属性：判断是否可以切换到下一P
    var canGoToNext: Bool {
        guard let currentIndex = parts.firstIndex(where: { $0.page == currentPage }) else { return false }
        return currentIndex < parts.count - 1
    }
    
    // 指令：切换到上一P
    func goToPreviousPart() {
        guard let currentIndex = parts.firstIndex(where: { $0.page == currentPage }) else { return }
        if currentIndex > 0 {
            currentPage = parts[currentIndex - 1].page
        }
    }
    
    // 指令：切换到下一P
    func goToNextPart() {
        guard let currentIndex = parts.firstIndex(where: { $0.page == currentPage }) else { return }
        if currentIndex < parts.count - 1 {
            currentPage = parts[currentIndex + 1].page
        }
    }
    // 指令：跳转到指定的一P
    func goToPart(page: Int) {
        // 检查请求的 page 是否存在于列表中
        if parts.contains(where: { $0.page == page }) {
            currentPage = page
        }
    }
}