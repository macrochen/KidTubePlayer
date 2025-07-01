import SwiftUI

struct VideoCardView: View {
    let video: Video
    var isSelected: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { // 增加了 VStack 内部的间距
            // --- 缩略图部分 (保持不变) ---
            ZStack(alignment: .topTrailing) {
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
                .cornerRadius(12) // 圆角稍微小一点，更精致
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                        .padding([.top, .trailing], 8)
                        .shadow(radius: 2)
                }
            }
            
            // --- 视频信息部分 (全新布局) ---
            HStack(alignment: .top, spacing: 12) {
                // 作者头像 (用一个系统图标代替)
                Image(systemName: "person.crop.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    // 视频标题
                    Text(video.title)
                        .font(.headline)
                        .fontWeight(.semibold) // 使用 semibold 看起来更清晰
                        .lineLimit(2) // 最多显示两行
                        .foregroundColor(.primary)
                    
                    // 作者、播放量和上传时间
                    Text("\(video.author) • \(video.viewCount.formattedString) 次观看 • \(video.uploadDate.timeAgoDisplay())")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding()
    }
}

// --- 小工具：用于格式化数字和日期 ---

extension Int {
    /// 将数字格式化为易于阅读的字符串 (例如 150000 -> "15万")
    var formattedString: String {
        let number = Double(self)
        let thousand = number / 1000
        let million = number / 1000000
        let billion = number / 1000000000
        
        if billion >= 1.0 {
            return "\(String(format: "%.1f", billion))亿"
        } else if million >= 1.0 {
            return "\(String(format: "%.1f", million))百万"
        } else if thousand >= 10.0 { // 大于1万才显示“万”
             return "\(String(format: "%.1f", number / 10000))万"
        } else {
            return "\(self)"
        }
    }
}

extension Date {
    /// 将日期转换为相对时间的字符串 (例如 "11小时前")
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "zh_CN") // 确保是中文环境
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}


// --- 预览代码 ---
struct VideoCardView_Previews: PreviewProvider {
    static var previews: some View {
        VideoCardView(video: VideoProvider.allVideos.first!)
            .previewLayout(.fixed(width: 350, height: 300))
            .padding()
    }
}
