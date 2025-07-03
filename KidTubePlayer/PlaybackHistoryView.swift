import SwiftUI
import SwiftData

struct PlaybackHistoryView: View {
    @Query(sort: \PlaybackRecord.startTime, order: .reverse) var records: [PlaybackRecord]
    
    @State private var displayGroupedRecords: [Date: [PlaybackRecord]] = [:]
    @State private var displaySortedDates: [Date] = []
    
    var body: some View {
        List {
            // 通过 ForEach 遍历排序后的日期
            ForEach(displaySortedDates, id: \.self) { date in
                // 为每个日期创建一个 Section
                Section(header: headerView(for: date)) {
                    // 调用新的辅助方法来构建 Section 的内容，从而简化 body 的结构
                    sectionContent(for: date)
                }
            }
        }
        .navigationTitle("播放历史")
        .onChange(of: records) {
            // 当原始记录变化时，更新用于显示的记录
            updateDisplayRecords()
        }
        .onAppear {
            // 视图出现时，更新用于显示的记录
            updateDisplayRecords()
        }
    }
    
    /// 将记录按日期分组并排序，以供视图使用
    private func updateDisplayRecords() {
        displayGroupedRecords = Dictionary(grouping: records) { $0.recordDate }
        displaySortedDates = displayGroupedRecords.keys.sorted(by: >)
    }

    /// 为 Section 创建头部视图
    private func headerView(for date: Date) -> some View {
        let totalDuration = displayGroupedRecords[date]?.reduce(0) { $0 + $1.duration } ?? 0
        
        return HStack {
            Text(formatDate(date))
                .font(.headline)
            Spacer()
            Text("总时长: \(formatDuration(totalDuration))")
                .font(.subheadline)
                .foregroundStyle(.secondary) // [修改] 使用 foregroundStyle 替代 foregroundColor
        }
        .padding(.vertical, 8)
    }
    
    /// [新增] 这是一个辅助方法，用于构建 Section 内部的视图内容。
    /// 将这部分逻辑提取出来可以解决编译器无法在合理时间内完成类型检查的问题。
    @ViewBuilder
    private func sectionContent(for date: Date) -> some View {
        ForEach(displayGroupedRecords[date] ?? []) { record in
            VStack(alignment: .leading, spacing: 5) {
                Text(record.videoTitle)
                    .font(.headline)
                Text("观看了 \(formatDuration(record.duration))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary) // [修改] 使用 foregroundStyle 替代 foregroundColor
                Text("起止时间: \(formatTime(record.startTime)) - \(formatTime(record.endTime))")
                    .font(.caption)
                    .foregroundStyle(.tertiary) // [修改] 使用 foregroundStyle 替代 foregroundColor
            }
            .padding(.vertical, 5)
        }
    }
    
    /// 格式化日期用于 Section Header 显示
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        
        if Calendar.current.isDateInToday(date) {
            return "今天"
        } else if Calendar.current.isDateInYesterday(date) {
            return "昨天"
        }
        
        return formatter.string(from: date)
    }
    
    /// 格式化时间
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    /// 格式化时长
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)小时\(remainingMinutes)分钟"
        } else if remainingMinutes > 0 {
            return "\(remainingMinutes)分钟"
        } else {
            return "不足1分钟"
        }
    }
}

struct PlaybackHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlaybackHistoryView()
        }
    }
}
