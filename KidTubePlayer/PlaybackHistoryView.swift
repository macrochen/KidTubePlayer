
//
//  PlaybackHistoryView.swift
//  KidTubePlayer
//
//  Created by Gemini on 2025/7/3.
//

import SwiftUI

struct PlaybackHistoryView: View {
    
    @State private var groupedRecords: [Date: [PlaybackRecord]] = [:]
    
    // 将日期数组也作为状态，以便排序
    @State private var sortedDates: [Date] = []

    var body: some View {
        List {
            ForEach(sortedDates, id: \.self) { date in
                Section(header: headerView(for: date)) {
                    ForEach(groupedRecords[date] ?? []) { record in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(record.videoTitle)
                                .font(.headline)
                            Text("观看了 \(formatDuration(record.duration))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }
        .navigationTitle("播放历史")
        .onAppear(perform: loadHistory)
    }
    
    private func loadHistory() {
        let records = PlaybackHistoryManager.shared.fetchGroupedRecords()
        self.groupedRecords = records
        // 对日期进行降序排序，最新的在最前面
        self.sortedDates = records.keys.sorted(by: >)
    }
    
    private func headerView(for date: Date) -> some View {
        let totalDuration = groupedRecords[date]?.reduce(0) { $0 + $1.duration } ?? 0
        
        return HStack {
            Text(formatDate(date))
                .font(.headline)
            Spacer()
            Text("总时长: \(formatDuration(totalDuration))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
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

