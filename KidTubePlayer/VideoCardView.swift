import SwiftUI

struct VideoCardView: View {
    let video: Video
    var isSelected: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                .cornerRadius(12)
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
                // 关键：使用 AsyncImage 来加载作者头像
                AsyncImage(url: video.authorAvatarURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } placeholder: {
                    // 如果加载失败或URL不存在，显示占位符
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // 视频标题
                    Text(video.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
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

// --- 小工具：用于格式化数字和日期 (保持不变) ---

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
        // 创建一个带头像URL的示例视频用于预览
        let sampleVideo = Video(
            id: "_U-7oN5AdmU",
            title: "Minecraft Speedrunner VS $100,000 Bounty Hunter",
            author: "Dream",
            viewCount: 158349012,
            uploadDate: Calendar.current.date(byAdding: .hour, value: -11, to: Date())!,
            authorAvatarURL: URL(string: "https://yt3.ggpht.com/ytc/AIdro_k-vC2rcK2j_b4Y_Z3-a_y-M-s_z-z_Z-z_Z-z=s88-c-k-c0x00ffffff-no-rj") // 示例URL
        )
        
        VideoCardView(video: sampleVideo)
            .previewLayout(.fixed(width: 350, height: 300))
            .padding()
    }
}
