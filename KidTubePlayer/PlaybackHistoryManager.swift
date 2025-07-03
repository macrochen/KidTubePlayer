
//
//  PlaybackHistoryManager.swift
//  KidTubePlayer
//
//  Created by Gemini on 2025/7/3.
//

import Foundation

/// 负责管理播放历史记录的读写操作
class PlaybackHistoryManager {
    
    static let shared = PlaybackHistoryManager()
    
    private let storageURL: URL
    
    private init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageURL = documentsDirectory.appendingPathComponent("playback_history.json")
    }
    
    /// 添加一条新的播放记录
    /// - Parameter record: 要添加的记录
    func addRecord(_ record: PlaybackRecord) {
        var allRecords = fetchAllRecords()
        allRecords.append(record)
        saveRecords(allRecords)
    }
    
    /// 获取所有播放记录
    /// - Returns: 一个包含所有记录的数组
    func fetchAllRecords() -> [PlaybackRecord] {
        do {
            let data = try Data(contentsOf: storageURL)
            let records = try JSONDecoder().decode([PlaybackRecord].self, from: data)
            return records
        } catch {
            // 如果文件不存在或解码失败，返回一个空数组
            return []
        }
    }
    
    /// 获取按日期分组的播放记录
    /// - Returns: 一个字典，键是日期，值是当天的播放记录数组
    func fetchGroupedRecords() -> [Date: [PlaybackRecord]] {
        let allRecords = fetchAllRecords()
        // 使用Swift的Dictionary(grouping:by:)方法可以非常方便地实现分组
        let grouped = Dictionary(grouping: allRecords) { (record) -> Date in
            return Calendar.current.startOfDay(for: record.startTime)
        }
        return grouped
    }
    
    /// 保存所有播放记录到文件
    /// - Parameter records: 要保存的完整记录数组
    private func saveRecords(_ records: [PlaybackRecord]) {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Error saving playback history: \(error)")
        }
    }
}

