import SwiftUI

struct VideoCardView: View {
    let video: Video
    var isSelected: Bool = false
    var watchedPercentage: Double = 0.0 // 新增：观看百分比 (0.0 - 1.0)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // --- 缩略图部分 ---
            ZStack(alignment: .bottomLeading) { // 修改对齐方式以便放置平台图标
                AsyncImage(url: video.thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay(ProgressView())
                }
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                
                // 关键：在左下角添加平台图标
                PlatformIconView(platform: video.platform)
                    .padding(8)
                
                // 选中标记（移到右上角）
                if isSelected {
                    ZStack {
                        Rectangle().fill(.clear) // 创建一个占满空间的透明视图
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                            .padding([.top, .trailing], 8)
                            .shadow(radius: 2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
                
                // 观看进度条
                GeometryReader {
                    geometry in
                    Rectangle()
                        .fill(.red)
                        .frame(width: geometry.size.width * watchedPercentage, height: 4) // 高度固定为4
                        .offset(y: geometry.size.height - 4) // 放置在底部
                }
            }
            
            // --- 视频信息部分 ---
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text("\(video.author) • \(video.viewCount.formattedString) 次观看 • \(video.uploadDate.timeAgoDisplay())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
    }
}

// 新增：一个用于显示平台图标的小视图
struct PlatformIconView: View {
    let platform: Platform
    
    var body: some View {
        // 根据平台显示不同的图标和颜色
        Image(systemName: platform == .youtube ? "play.tv.fill" : "play.rectangle.on.rectangle.fill")
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                .white,
                platform == .youtube ? .red : Color(red: 0.2, green: 0.7, blue: 0.9) // Bilibili 的蓝色
            )
            .font(.title3)
            .padding(6)
            .background(.clear) 
            .clipShape(Circle())
    }
}


// ... (格式化工具和预览代码保持不变, 但预览需要更新)
extension Int {
    var formattedString: String {
        let number = Double(self)
        if number >= 1_000_000_000 { return "\(String(format: "%.1f", number / 1_000_000_000))亿" }
        if number >= 1_000_000 { return "\(String(format: "%.1f", number / 1_000_000))百万" }
        if number >= 10_000 { return "\(String(format: "%.1f", number / 10_000))万" }
        return "\(self)"
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

struct VideoCardView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleVideo = Video(id: "sampleID", platform: .youtube, title: "Sample Video Title", author: "Sample Author", viewCount: 1000, uploadDate: Date(), authorAvatarURL: nil, thumbnailURL: URL(string: "https://i.ytimg.com/vi/K-N_s5Yd2Yc/hqdefault.jpg"))
        VideoCardView(video: sampleVideo)
            .previewLayout(.fixed(width: 350, height: 300))
            .padding()
    }
}
